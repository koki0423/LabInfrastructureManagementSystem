# Alpha版リリース

## 前提

- `main` にリリース対象の変更がpush済みであること。
- ローカルとCIの両方でパッケージのビルド・動作確認が完了していること。
- GitHub Actionsが有効であり、ワークフローの`GITHUB_TOKEN`に`contents: write`が許可されていること。

## リリース手順

alphaタグは必ず `vX.Y.Z-alpha.N` の形式にします。例として、最初のv1.0.0 alphaを作成する場合は次を実行します。

```bash
git switch main
git pull --ff-only
git push origin main
git tag -a v1.0.0-alpha.1 -m "LIMS v1.0.0 alpha 1"
git push origin v1.0.0-alpha.1
```

タグのpushにより `Build alpha Debian package` ワークフローが実行されます。タグのソースだけをcheckoutし、次のDebian版番号でパッケージを生成します。

```text
Git tag:        v1.0.0-alpha.1
Debian version: 1.0.0~alpha.1
Asset:          lims-system_1.0.0~alpha.1_amd64.deb
```

`~alpha` を使うため、正式版 `1.0.0` はこのalpha版より新しいバージョンとしてAPTに認識されます。

## 成果物の確認

ワークフロー成功後、GitHub Releasesのalpha pre-releaseに次を添付します。

- `lims-system_*.deb`
- `SHA256SUMS`

同じファイルは30日間、Actions runのartifactとしても取得できます。利用前にチェックサムを検証します。

```bash
sha256sum -c SHA256SUMS
sudo apt install ./lims-system_1.0.0~alpha.1_amd64.deb
```

同じタグのワークフローを再実行した場合、既存のRelease assetは新しいビルド成果物で置き換えられます。タグを打ち直さず、新しいalphaを配布する場合はalpha番号を増やして新しいタグを作成してください。
