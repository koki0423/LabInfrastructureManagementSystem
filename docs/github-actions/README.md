# GitHub Actions

[`release-alpha.yml`](../../.github/workflows/release-alpha.yml) は、`vX.Y.Z-alpha.N` タグのpushを契機にLinuxコンテナで`.deb`をビルドします。成果物はActions ArtifactとGitHubのalpha pre-releaseへ添付されます。

通常のリリース操作は[alpha版リリース手順](../release.md)を参照してください。

正式版GitHub ReleaseおよびAPTリポジトリ公開は、将来のワークフロー拡張候補です。
