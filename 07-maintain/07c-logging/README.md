# 7c — Verbose logging

Docs: [Debugging Terraform](https://developer.hashicorp.com/terraform/internals/v1.12.x/debugging), [enable logging](https://developer.hashicorp.com/terraform/tutorials/configuration-language/troubleshooting-workflow#enable-terraform-logging).

Terraform is quiet unless a run fails. When you need the provider conversation, set `TF_LOG` for that one command.

```bash
TF_LOG=INFO terraform plan
TF_LOG=DEBUG terraform plan
TF_LOG=TRACE TF_LOG_PATH=./terraform.log terraform plan
```

Levels, from least output to most: `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`.

`TRACE` includes internal details and the provider RPC payloads. It can include credentials, tokens, and the contents of sensitive variables. Write it to `TF_LOG_PATH`, read what you need, and delete the file. Do not paste a TRACE log into a ticket without reading it.

Unset the variable when you are done. A shell that exports `TF_LOG=TRACE` forever will fill disks and leak secrets into every later plan.

## Core and provider separately

| Variable | Stream |
|---|---|
| `TF_LOG` | both |
| `TF_LOG_CORE` | Terraform core: graph, backend, state |
| `TF_LOG_PROVIDER` | provider plugins |

Set `TF_LOG_PROVIDER=DEBUG` when the cloud API call is the suspect and core's graph walk is noise. Set `TF_LOG_CORE=DEBUG` when the backend, the lock, or the graph is the suspect.

A crash writes `crash.log` in the working directory. That file can also contain sensitive values. It is in `.gitignore` in this repo. HashiCorp asks for it on a bug report; redact it first.

## What logs are for

Logging explains a failure you already have. It does not change the plan. A question that says "set TF_LOG to make apply skip a resource" is wrong. The level only changes how much is printed.

`TF_LOG=TRACE` is the setting to remember as "most verbose." `INFO` is enough to see which provider is selected and whether the backend initialized.
