FROM mysql:8.4

# 文字化け対策
ENV LANG=C.UTF-8

# 初期化SQLのコピー
COPY ./DB/lims_v1-init.sql /docker-entrypoint-initdb.d/10-init.sql