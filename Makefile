
release: release.agent release.backend

release.%:
	rm -rf _build/prod/rel/$(*)
	MIX_ENV=prod mix do clean
	cd apps/lm_$(*)_web; MIX_ENV=prod mix do compile, phx.digest
	MIX_ENV=prod mix release $(*)

run.iex.%:
	cd apps/lm_$(*)_web; iex -S mix phx.server