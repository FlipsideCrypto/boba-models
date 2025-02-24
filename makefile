DBT_TARGET ?= dev

deploy_streamline_functions:
	rm -f package-lock.yml && dbt clean && dbt deps
	dbt run -s livequery_models.deploy.core --vars '{"UPDATE_UDFS_AND_SPS":True}' -t $(DBT_TARGET)
	dbt run-operation fsc_utils.create_evm_streamline_udfs --vars '{"UPDATE_UDFS_AND_SPS":True}' -t $(DBT_TARGET)

cleanup_time:
	rm -f package-lock.yml && dbt clean && dbt deps

deploy_streamline_tables:
	rm -f package-lock.yml && dbt clean && dbt deps
ifeq ($(findstring dev,$(DBT_TARGET)),dev)
	dbt run -m "fsc_evm,tag:bronze_core" "fsc_evm,tag:bronze_receipts" --vars '{"STREAMLINE_USE_DEV_FOR_EXTERNAL_TABLES":True}' -t $(DBT_TARGET)
else
	dbt run -m "fsc_evm,tag:bronze_core" "fsc_evm,tag:bronze_receipts" -t $(DBT_TARGET)
endif
	dbt run -m "fsc_evm,tag:streamline_core_complete" "fsc_evm,tag:streamline_core_realtime" "fsc_evm,tag:streamline_core_realtime_receipts" "fsc_evm,tag:streamline_core_complete_receipts" "fsc_evm,tag:utils" --full-refresh -t $(DBT_TARGET)

deploy_streamline_requests:
	rm -f package-lock.yml && dbt clean && dbt deps
	dbt run -m "fsc_evm,tag:streamline_core_complete" "fsc_evm,tag:streamline_core_realtime" "fsc_evm,tag:streamline_core_realtime_receipts" "fsc_evm,tag:streamline_core_complete_receipts" --vars '{"STREAMLINE_INVOKE_STREAMS":True}' -t $(DBT_TARGET)

deploy_streamline_history:
	rm -f package-lock.yml && dbt clean && dbt deps
	dbt run -m "fsc_evm,tag:streamline_core_complete" "fsc_evm,tag:streamline_core_history" "fsc_evm,tag:streamline_core_history_receipts" "fsc_evm,tag:streamline_core_complete_receipts" --vars '{"STREAMLINE_INVOKE_STREAMS":True}' -t $(DBT_TARGET)

deploy_github_actions:
	dbt run -s livequery_models.deploy.marketplace.github --vars '{"UPDATE_UDFS_AND_SPS":True}' -t $(DBT_TARGET)
	dbt seed -s github_actions__workflows -t $(DBT_TARGET)
	dbt run -m "fsc_evm,tag:gha_tasks" --full-refresh -t $(DBT_TARGET)
ifeq ($(findstring dev,$(DBT_TARGET)),dev)
	dbt run-operation fsc_utils.create_gha_tasks --vars '{"START_GHA_TASKS":False}' -t $(DBT_TARGET)
else
	dbt run-operation fsc_utils.create_gha_tasks --vars '{"START_GHA_TASKS":True}' -t $(DBT_TARGET)
endif

deploy_new_github_action:
	dbt run-operation fsc_evm.drop_github_actions_schema -t $(DBT_TARGET)
	dbt seed -s github_actions__workflows -t $(DBT_TARGET)
	dbt run -m "fsc_evm,tag:gha_tasks" --full-refresh -t $(DBT_TARGET)
ifeq ($(findstring dev,$(DBT_TARGET)),dev)
	dbt run-operation fsc_utils.create_gha_tasks --vars '{"START_GHA_TASKS":False}' -t $(DBT_TARGET)
else
	dbt run-operation fsc_utils.create_gha_tasks --vars '{"START_GHA_TASKS":True}' -t $(DBT_TARGET)
endif

deploy_phase_2:
	rm -f package-lock.yml && dbt clean && dbt deps
	dbt run -m "fsc_evm,tag:phase_2,tag:bronze_abis" --vars '{"BRONZE_CONTRACT_ABIS_FULL_REFRESH":"true"}' -t $(DBT_TARGET)
	dbt run -m "fsc_evm,tag:phase_2" --exclude tag:bronze_abis -t $(DBT_TARGET)

.PHONY: deploy_streamline_functions deploy_streamline_tables deploy_streamline_requests deploy_github_actions cleanup_time deploy_new_github_action deploy_streamline_history deploy_phase_2