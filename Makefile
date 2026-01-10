.PHONY: dev supabase-fetch supabase-up supabase-down dev-app db-schema db-reset supabase-init deploy deploy-watch deploy-log deploy-status deploy-log-full

# 初回セットアップ用: Supabase の docker セットを取得
supabase-fetch:
	infra/supabase/fetch-supabase-compose.sh

# Supabase スタックを起動 (バックグラウンド)
supabase-up:
	@if [ ! -f infra/supabase/bundle/.env ]; then \
		if [ -f infra/supabase/bundle/.env.example ]; then \
			cp infra/supabase/bundle/.env.example infra/supabase/bundle/.env; \
		fi; \
		echo "[supabase-up] .env が無いので infra/supabase/bundle/.env を用意しました（必要なら編集してください）。"; \
	fi
	cd infra/supabase/bundle && docker compose up -d db rest auth kong storage meta

# Supabase スタックを停止
supabase-down:
	cd infra/supabase/bundle && docker compose down

db-reset-local:
	PGSSLMODE=disable supabase db reset --db-url "postgresql://postgres:your-super-secret-and-long-postgres-password@localhost:54322/postgres"


ifneq (,$(wildcard ./.env))
	include .env
	export
endif

# TODO: test this script
# ifneq (,$(wildcard ./.env))
#     include .env
#     export
# endif

# db-reset-remote:
# 	supabase db reset --db-url $(DATABASE_URL)

# Supabase の初期セットアップ (何度実行しても安全な想定)
supabase-init: supabase-fetch supabase-up db-schema

# Next.js アプリだけ起動
dev-app:
	npm run dev

# ワンコマンド開発エントリーポイント
# - Supabase を起動
# - Next.js 開発サーバを起動
dev: supabase-up dev-app

# =============================================================================
# Deployment Commands (GitHub Actions via gh CLI)
# =============================================================================

# デプロイワークフローを実行
deploy:
	gh workflow run deploy.yml --ref $$(git rev-parse --abbrev-ref HEAD)
	@echo "Workflow started. Run 'make deploy-watch' to monitor progress."

# デプロイ状況をリアルタイムで監視
deploy-watch:
	gh run watch

# 失敗したジョブのログを表示
deploy-log:
	gh run view --log-failed

# 最近のデプロイ履歴を表示
deploy-status:
	gh run list --workflow=deploy.yml --limit 5

# 最新のデプロイログを全て表示
deploy-log-full:
	gh run view --log
