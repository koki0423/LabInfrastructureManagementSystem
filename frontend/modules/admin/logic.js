import { Router } from '../../js/router.js';
import { API } from '../../js/api.js?v=20261013-1';
import { AppState } from '../../js/app_state.js';
import { escapeHtml } from '../../js/dom_utils.js';
import { setAuthToken, setAuthProfile, clearAuthSession, hasCapability } from '../../js/auth_session.js?v=20260707-1';
import { isMaintenanceModeEnabled, MAINTENANCE_MODE_KEY, setMaintenanceModeEnabled } from '../../js/maintenance_mode.js';
import { confirmAction } from '../../js/ui_dialog.js';
import { runWithButtonLoading, setControlsDisabled } from '../../js/ui_loading.js';
import { hidePageFeedback, showApiPageFeedback, showPageFeedback } from '../../js/ui_feedback.js';

const adminState = {
    genres: [],
    flash: null,
    genreLoading: false,
    masterSearchResults: [],
    masterSearchLoading: false,
    masterEditSaving: false,
    masterEditIndex: -1
};
let maintenanceStorageListenerBound = false;

async function loadNfcReader() {
    return import('../../js/nfcReader.js');
}

function getActiveAdminFeedbackId() {
    return [
        'admin-login-feedback',
        'admin-main-feedback',
        'admin-register-feedback',
        'admin-genres-feedback',
        'admin-master-edit-feedback',
        'admin-master-edit-modal-feedback'
    ].find((id) => document.getElementById(id)) || '';
}

function clearActiveAdminFeedback() {
    const feedbackId = getActiveAdminFeedbackId();
    if (feedbackId) {
        hidePageFeedback(feedbackId);
    }
}

function showActiveAdminFeedback(message, tone = 'error') {
    const feedbackId = getActiveAdminFeedbackId();
    if (feedbackId) {
        showPageFeedback(feedbackId, message, tone);
    }
}

function setAdminFlash(view, message, tone = 'success') {
    adminState.flash = {
        view,
        message,
        tone
    };
}

function consumeAdminFlash(view, feedbackId) {
    hidePageFeedback(feedbackId);

    if (!adminState.flash || adminState.flash.view !== view) {
        return;
    }

    showPageFeedback(feedbackId, adminState.flash.message, adminState.flash.tone);
    adminState.flash = null;
}

function setGenreControlsLoading(isLoading) {
    setControlsDisabled([
        '#new-genre-name',
        '#new-genre-code',
        '#admin-genre-add-btn',
        '#genre-list-body .sm-btn',
        '#admin-genres-back-btn'
    ], isLoading);
}

function getGenreId(genre) {
    return Number(genre?.id ?? genre?.genre_id);
}

function getGenreName(genre) {
    return String(genre?.name ?? genre?.genre_name ?? '-');
}

function getGenreCode(genre) {
    return String(genre?.code ?? genre?.genre_code ?? '');
}

function isGenreDisabled(genre) {
    return genre?.is_disabled === true || Number(genre?.is_disabled) === 1;
}

function getMasterEditTarget() {
    const index = adminState.masterEditIndex;
    if (!Number.isInteger(index) || index < 0) {
        return null;
    }
    return adminState.masterSearchResults[index] || null;
}

function replaceManagementNumberPrefix(managementNumber, genreCode) {
    const number = String(managementNumber || '').trim();
    const code = String(genreCode || '').trim();
    const separatorIndex = number.indexOf('-');
    if (!code || separatorIndex <= 0 || separatorIndex === number.length - 1) {
        return number;
    }
    return `${code}${number.slice(separatorIndex)}`;
}

function setMasterSearchControlsLoading(isLoading) {
    adminState.masterSearchLoading = isLoading;
    setControlsDisabled([
        '#admin-master-search-query',
        '#admin-master-search-btn',
        '#admin-master-search-results .sm-btn',
        '#admin-master-edit-back-btn'
    ], isLoading);
}

function setMasterEditControlsLoading(isLoading) {
    adminState.masterEditSaving = isLoading;
    setControlsDisabled([
        '#admin-master-edit-form input',
        '#admin-master-edit-form select',
        '#admin-master-edit-form .back-btn'
    ], isLoading);
}

function renderMasterSearchResults() {
    const tbody = document.getElementById('admin-master-search-results');
    if (!tbody) {
        return;
    }

    if (adminState.masterSearchResults.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="table-empty-state">該当する備品はありません</td></tr>';
        return;
    }

    tbody.innerHTML = adminState.masterSearchResults.map((assetSet, index) => {
        const master = assetSet?.master || {};
        const asset = assetSet?.asset || {};
        const genre = adminState.genres.find((entry) => getGenreId(entry) === Number(master.genre_id));
        const genreLabel = genre
            ? `${getGenreName(genre)} (${getGenreCode(genre)})${isGenreDisabled(genre) ? '・無効' : ''}`
            : '-';
        const managementNumber = master.management_number || asset.management_number || '-';

        return `
            <tr>
                <td>${escapeHtml(managementNumber)}</td>
                <td>${escapeHtml(master.name || asset.name || '-')}</td>
                <td>${escapeHtml(asset.serial || '-')}</td>
                <td>${escapeHtml(genreLabel)}</td>
                <td>
                    <button class="sm-btn" onclick="AdminController.openMasterEditByIndex(${index})">編集</button>
                </td>
            </tr>
        `;
    }).join('');
}

function renderMaintenanceModeState() {
    const status = document.getElementById('admin-maintenance-status');
    const toggleButton = document.getElementById('admin-maintenance-toggle-btn');
    if (!status || !toggleButton) {
        return;
    }

    const isEnabled = isMaintenanceModeEnabled();
    status.textContent = isEnabled
        ? '現在は有効です。トップメニューでは管理者ログイン以外の操作を停止します。'
        : '現在は無効です。トップメニューは通常どおり利用できます。';

    toggleButton.textContent = isEnabled
        ? 'メンテナンスモードをOFF'
        : 'メンテナンスモードをON';
    toggleButton.className = isEnabled ? 'primary-btn' : 'secondary-btn';
}

function bindMaintenanceStorageListener() {
    if (maintenanceStorageListenerBound || typeof window === 'undefined') {
        return;
    }

    window.addEventListener('storage', (event) => {
        if (event.key && event.key !== MAINTENANCE_MODE_KEY) {
            return;
        }

        renderMaintenanceModeState();
    });

    maintenanceStorageListenerBound = true;
}

window.AdminController = {
    // ===============================================
    // ログイン・管理者登録関連
    // ===============================================
    async NfcRead() {
        const input = document.getElementById('admin-id');

        try {
            const { scanStudentIdWithRetry } = await loadNfcReader();
            const result = await scanStudentIdWithRetry(9, 2000);

            if (result.ok) {
                input.value = result.studentId;
                clearActiveAdminFeedback();
                return;
            }

            if (!result.cancelled) {
                showActiveAdminFeedback('NFC読み取り失敗: ' + result.error, 'error');
            }
        } catch (err) {
            console.error("scan error:", err);
            showActiveAdminFeedback(
                'NFC読み取り中にエラーが発生しました: ' + (err instanceof Error ? err.message : String(err)),
                'error'
            );
        }
    },

    async login() {
        const form = document.getElementById('form-admin-login');
        const idInput = document.getElementById('admin-id');
        const passInput = document.getElementById('admin-pass');
        if (!form || !idInput || !passInput) {
            return;
        }

        hidePageFeedback('admin-login-feedback');
        if (!form.reportValidity()) {
            showPageFeedback('admin-login-feedback', '入力内容を確認してください。', 'error');
            return;
        }

        const controls = [
            '#admin-id',
            '#admin-pass',
            '#admin-login-back-btn',
            '#form-admin-login .nfc-btn'
        ];

        setControlsDisabled(controls, true);
        try {
            await runWithButtonLoading('#admin-login-btn', { busyText: 'ログイン中...' }, async () => {
                const data = await API.auth.login({ id: idInput.value, password: passInput.value });
                if (!data || !data.token) {
                    showPageFeedback('admin-login-feedback', 'ログイン応答が不正です。', 'error');
                    return;
                }

                setAuthToken(data.token);
                const me = await API.auth.me();
                if (!hasCapability('assets.admin', me)) {
                    clearAuthSession();
                    showPageFeedback('admin-login-feedback', '備品管理の管理者権限がありません。', 'error');
                    return;
                }

                setAuthProfile(me);
                Router.to('admin-main');
            });
        } catch (error) {
            clearAuthSession();
            showApiPageFeedback('admin-login-feedback', error, 'ログインに失敗しました。');
        } finally {
            setControlsDisabled(controls, false);
        }
    },

    async logout() {
        const confirmed = await confirmAction({
            title: 'ログアウト確認',
            message: '管理者メニューからログアウトしますか？',
            confirmLabel: 'ログアウト',
            cancelLabel: 'キャンセル',
            tone: 'warning'
        });

        if (!confirmed) {
            return;
        }

        clearAuthSession();
        Router.to('main-menu');
    },

    toRegister() {
        Router.to('admin-register');
    },

    toMasterEdit() {
        Router.to('admin-master-edit');
    },

    async toggleMaintenanceMode() {
        const isEnabled = isMaintenanceModeEnabled();
        const nextEnabled = !isEnabled;
        const actionLabel = nextEnabled ? '有効化' : '解除';

        const confirmed = await confirmAction({
            title: 'メンテナンスモード確認',
            message: nextEnabled
                ? 'メンテナンスモードを有効化しますか？\nトップメニューでは管理者ログイン以外の操作が利用できなくなります。'
                : 'メンテナンスモードを解除しますか？\nトップメニューの利用制限を解除します。',
            confirmLabel: actionLabel,
            cancelLabel: 'キャンセル',
            tone: nextEnabled ? 'warning' : 'primary'
        });

        if (!confirmed) {
            return;
        }

        setMaintenanceModeEnabled(nextEnabled);
        renderMaintenanceModeState();
        showPageFeedback(
            'admin-main-feedback',
            nextEnabled
                ? 'メンテナンスモードを有効にしました。'
                : 'メンテナンスモードを解除しました。',
            'success'
        );
    },

    async submitRegister() {
        const form = document.getElementById('form-admin-reg');
        if (!form) {
            return;
        }

        hidePageFeedback('admin-register-feedback');
        if (!form.reportValidity()) {
            showPageFeedback('admin-register-feedback', '入力に不備があります。必須項目を入力してください。', 'error');
            return;
        }

        const id = document.getElementById('admin-id').value;
        const password = new FormData(form).get('password');
        const role = document.getElementById('admin-role')?.value || 'asset_admin';
        const controls = [
            '#admin-id',
            '#form-admin-reg input[name="password"]',
            '#admin-role',
            '#form-admin-reg .nfc-btn',
            '#admin-register-back-btn'
        ];

        setControlsDisabled(controls, true);
        try {
            await runWithButtonLoading('#admin-register-submit-btn', { busyText: '登録中...' }, async () => {
                await API.admin.register({ id, password, role });
                setAdminFlash('main', '管理者を追加登録しました。', 'success');
                Router.to('admin-main');
            });
        } catch (error) {
            if (error?.response?.status === 409) {
                showPageFeedback('admin-register-feedback', 'そのIDは既に存在します。', 'warning');
                return;
            }

            showApiPageFeedback('admin-register-feedback', error, '登録に失敗しました。');
        } finally {
            setControlsDisabled(controls, false);
        }
    },

    submitRegisterWithAlert() {
        return this.submitRegister();
    },

    // ===============================================
    // 備品ジャンル管理
    // ===============================================
    async initGenreMaster() {
        await this.initAdmin('genres');
    },

    async initAdmin(view) {
        if (view === 'login') {
            consumeAdminFlash('login', 'admin-login-feedback');
            return;
        }

        if (view === 'main') {
            consumeAdminFlash('main', 'admin-main-feedback');
            renderMaintenanceModeState();
            bindMaintenanceStorageListener();
            return;
        }

        if (view === 'register') {
            consumeAdminFlash('register', 'admin-register-feedback');
            return;
        }

        if (view === 'genres') {
            consumeAdminFlash('genres', 'admin-genres-feedback');
            await this.renderGenreList();
            return;
        }

        if (view === 'master-edit') {
            consumeAdminFlash('master-edit', 'admin-master-edit-feedback');
            try {
                adminState.genres = await AppState.loadGenres({ all: true, force: true });
            } catch (error) {
                console.error(error);
                showApiPageFeedback('admin-master-edit-feedback', error, 'ジャンル一覧の取得に失敗しました。');
            }
        }
    },

    async searchMasterEditTargets() {
        if (adminState.masterSearchLoading || adminState.masterEditSaving) {
            return;
        }

        const input = document.getElementById('admin-master-search-query');
        const query = input?.value.trim() || '';
        hidePageFeedback('admin-master-edit-feedback');

        if (!query) {
            showPageFeedback('admin-master-edit-feedback', '管理番号・備品名・シリアル番号のいずれかを入力してください。', 'error');
            return;
        }

        setMasterSearchControlsLoading(true);
        try {
            const response = await API.assets.search({ q: query });
            adminState.masterSearchResults = Array.isArray(response)
                ? response
                : (Array.isArray(response?.items) ? response.items : []);
            renderMasterSearchResults();
        } catch (error) {
            console.error(error);
            adminState.masterSearchResults = [];
            renderMasterSearchResults();
            showApiPageFeedback('admin-master-edit-feedback', error, '備品の検索に失敗しました。');
        } finally {
            setMasterSearchControlsLoading(false);
        }
    },

    async openMasterEditByIndex(index) {
        if (adminState.masterSearchLoading || adminState.masterEditSaving) {
            return;
        }

        const target = adminState.masterSearchResults[index];
        const master = target?.master;
        const asset = target?.asset;
        if (!master || !asset) {
            showPageFeedback('admin-master-edit-feedback', '対象データが見つかりません。', 'error');
            return;
        }

        try {
            if (adminState.genres.length === 0) {
                adminState.genres = await AppState.loadGenres({ all: true, force: true });
            }

            const currentGenreID = Number(master.genre_id);
            const genreSelect = document.getElementById('admin-master-edit-genre');
            if (!genreSelect) {
                return;
            }

            const selectableGenres = adminState.genres.filter((genre) => (
                !isGenreDisabled(genre) || getGenreId(genre) === currentGenreID
            ));
            genreSelect.innerHTML = selectableGenres.map((genre) => {
                const id = getGenreId(genre);
                const isCurrent = id === currentGenreID;
                const stateLabel = isGenreDisabled(genre) ? '（現在は無効）' : '';
                return `<option value="${id}"${isCurrent ? ' selected' : ''}>${escapeHtml(`${getGenreName(genre)} (${getGenreCode(genre)})${stateLabel}`)}</option>`;
            }).join('');

            adminState.masterEditIndex = index;
            document.getElementById('admin-master-edit-current-number').value = master.management_number || asset.management_number || '';
            document.getElementById('admin-master-edit-name').value = master.name || asset.name || '';
            document.getElementById('admin-master-edit-serial').value = asset.serial || '';
            hidePageFeedback('admin-master-edit-modal-feedback');
            this.updateManagementNumberPreview();

            const modal = document.getElementById('admin-master-edit-modal');
            if (modal) {
                modal.hidden = false;
            }
        } catch (error) {
            console.error(error);
            showApiPageFeedback('admin-master-edit-feedback', error, '編集画面の準備に失敗しました。');
        }
    },

    updateManagementNumberPreview() {
        const target = getMasterEditTarget();
        const nextNumberInput = document.getElementById('admin-master-edit-next-number');
        const genreSelect = document.getElementById('admin-master-edit-genre');
        if (!target || !nextNumberInput || !genreSelect) {
            return;
        }

        const master = target.master || {};
        const asset = target.asset || {};
        const genre = adminState.genres.find((entry) => getGenreId(entry) === Number(genreSelect.value));
        nextNumberInput.value = replaceManagementNumberPrefix(
            master.management_number || asset.management_number,
            getGenreCode(genre)
        );
    },

    closeMasterEditModal() {
        if (adminState.masterEditSaving) {
            return;
        }

        const modal = document.getElementById('admin-master-edit-modal');
        if (modal) {
            modal.hidden = true;
        }
        adminState.masterEditIndex = -1;
    },

    async saveMasterEdit() {
        if (adminState.masterEditSaving) {
            return;
        }

        const target = getMasterEditTarget();
        const form = document.getElementById('admin-master-edit-form');
        if (!target || !form) {
            showPageFeedback('admin-master-edit-feedback', '対象データが見つかりません。', 'error');
            return;
        }

        hidePageFeedback('admin-master-edit-modal-feedback');
        if (!form.reportValidity()) {
            showPageFeedback('admin-master-edit-modal-feedback', '入力内容を確認してください。', 'error');
            return;
        }

        const master = target.master || {};
        const asset = target.asset || {};
        const name = document.getElementById('admin-master-edit-name').value.trim();
        const serial = document.getElementById('admin-master-edit-serial').value.trim();
        const genreID = Number(document.getElementById('admin-master-edit-genre').value);
        const genre = adminState.genres.find((entry) => getGenreId(entry) === genreID);
        const currentGenreID = Number(master.genre_id);

        if (!genre || !Number.isInteger(genreID) || genreID <= 0) {
            showPageFeedback('admin-master-edit-modal-feedback', '変更先ジャンルを選択してください。', 'error');
            return;
        }
        if (isGenreDisabled(genre) && genreID !== currentGenreID) {
            showPageFeedback('admin-master-edit-modal-feedback', '無効なジャンルへ変更することはできません。', 'error');
            return;
        }

        const currentNumber = master.management_number || asset.management_number || '';
        const nextNumber = replaceManagementNumberPrefix(currentNumber, getGenreCode(genre));
        const confirmed = await confirmAction({
            title: '備品マスタ更新確認',
            message: `備品名・シリアル番号・ジャンルを更新しますか？\n管理番号: ${currentNumber} → ${nextNumber}\nジャンルを変更した場合は、旧管理番号のラベルを再発行してください。`,
            confirmLabel: '更新する',
            cancelLabel: 'キャンセル',
            tone: 'warning'
        });
        if (!confirmed) {
            return;
        }

        setMasterEditControlsLoading(true);
        try {
            const response = await runWithButtonLoading('#admin-master-edit-save-btn', { busyText: '更新中...' }, async () => (
                API.assets.updateMasterEdit(asset.asset_id, {
                    name,
                    serial,
                    genre_id: genreID
                })
            ));

            const updatedMaster = response?.master;
            const updatedAsset = response?.asset;
            if (updatedMaster && updatedAsset) {
                adminState.masterSearchResults = adminState.masterSearchResults.map((assetSet) => {
                    const candidateMaster = assetSet?.master || {};
                    const candidateAsset = assetSet?.asset || {};
                    if (Number(candidateMaster.asset_master_id) !== Number(updatedMaster.asset_master_id)) {
                        return assetSet;
                    }

                    return {
                        ...assetSet,
                        master: { ...candidateMaster, ...updatedMaster },
                        asset: {
                            ...candidateAsset,
                            ...(Number(candidateAsset.asset_id) === Number(updatedAsset.asset_id) ? updatedAsset : {}),
                            management_number: updatedMaster.management_number
                        }
                    };
                });
            }

            renderMasterSearchResults();
            const modal = document.getElementById('admin-master-edit-modal');
            if (modal) {
                modal.hidden = true;
            }
            adminState.masterEditIndex = -1;
            showPageFeedback(
                'admin-master-edit-feedback',
                `更新しました。管理番号: ${currentNumber} → ${nextNumber}`,
                'success'
            );
        } catch (error) {
            console.error(error);
            showApiPageFeedback('admin-master-edit-modal-feedback', error, '更新に失敗しました。');
        } finally {
            setMasterEditControlsLoading(false);
        }
    },

    async renderGenreList() {
        const tbody = document.getElementById('genre-list-body');
        if (!tbody) {
            return;
        }

        adminState.genreLoading = true;
        setGenreControlsLoading(true);
        try {
            const genres = await AppState.loadGenres({ all: true, force: true });
            adminState.genres = genres;

            tbody.innerHTML = genres.map((genre, index) => {
                const rowClass = genre.is_disabled ? ' class="admin-genre-row--disabled"' : '';
                const statusText = genre.is_disabled ? '無効' : '有効';
                const btnText = genre.is_disabled ? '有効化' : '無効化';

                return `
                    <tr${rowClass}>
                        <td>${escapeHtml(genre.id)}</td>
                        <td>${escapeHtml(genre.name)}</td>
                        <td>${escapeHtml(genre.code)}</td>
                        <td>${statusText}</td>
                        <td>
                            <button class="sm-btn" onclick="AdminController.toggleGenreByIndex(${index})">
                                ${btnText}
                            </button>
                        </td>
                    </tr>
                `;
            }).join('');
        } catch (error) {
            console.error(error);
            tbody.innerHTML = '<tr><td colspan="5" class="table-empty-state table-empty-state-error">ジャンル一覧の取得に失敗しました</td></tr>';
            showApiPageFeedback('admin-genres-feedback', error, 'ジャンル一覧の取得に失敗しました。');
        } finally {
            adminState.genreLoading = false;
            setGenreControlsLoading(false);
        }
    },

    async addGenre() {
        if (adminState.genreLoading) {
            return;
        }

        const name = document.getElementById('new-genre-name').value.trim();
        const code = document.getElementById('new-genre-code').value.trim();

        hidePageFeedback('admin-genres-feedback');
        if (!name || !code) {
            showPageFeedback('admin-genres-feedback', 'ジャンル名とコードを入力してください。', 'error');
            return;
        }

        adminState.genreLoading = true;
        setGenreControlsLoading(true);
        try {
            await runWithButtonLoading('#admin-genre-add-btn', { busyText: '追加中...' }, async () => {
                await API.genres.create({ name, code });
            });

            await AppState.refreshGenres();
            await this.renderGenreList();

            document.getElementById('new-genre-name').value = '';
            document.getElementById('new-genre-code').value = '';
            showPageFeedback('admin-genres-feedback', 'ジャンルを追加しました。', 'success');
        } catch (error) {
            console.error(error);
            showApiPageFeedback('admin-genres-feedback', error, 'ジャンルの追加に失敗しました。');
        } finally {
            adminState.genreLoading = false;
            setGenreControlsLoading(false);
        }
    },

    async toggleGenre(id, nextIsDisabledState, name, code) {
        const action = nextIsDisabledState ? '無効化' : '有効化';
        if (adminState.genreLoading) {
            return;
        }

        const confirmed = await confirmAction({
            title: 'ジャンル状態変更',
            message: `${name} を${action}しますか？`,
            confirmLabel: action,
            cancelLabel: 'キャンセル',
            tone: nextIsDisabledState ? 'warning' : 'primary'
        });
        if (!confirmed) {
            return;
        }

        hidePageFeedback('admin-genres-feedback');
        adminState.genreLoading = true;
        setGenreControlsLoading(true);
        try {
            await API.genres.update(id, {
                name,
                code,
                is_disabled: nextIsDisabledState
            });

            await AppState.refreshGenres();
            await this.renderGenreList();
            showPageFeedback('admin-genres-feedback', `${name} を${action}しました。`, 'success');
        } catch (error) {
            showApiPageFeedback('admin-genres-feedback', error, 'ジャンルの更新に失敗しました。');
        } finally {
            adminState.genreLoading = false;
            setGenreControlsLoading(false);
        }
    },

    async toggleGenreByIndex(index) {
        const genre = adminState.genres[index];
        if (!genre) {
            showPageFeedback('admin-genres-feedback', '対象ジャンルが見つかりません。', 'error');
            return;
        }

        await this.toggleGenre(genre.id, !genre.is_disabled, genre.name, genre.code);
    }
};

export function initAdmin(view) {
    return window.AdminController.initAdmin(view);
}
