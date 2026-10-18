# 6b — State locking

Docs: [State locking](https://developer.hashicorp.com/terraform/language/v1.12.x/state/locking), [state storage and locking](https://developer.hashicorp.com/terraform/language/v1.12.x/state/backends).

**Definition (exam):** **State locking** prevents multiple operations from **modifying state at the same time**. When one **`terraform apply`** (or another state-writing command) is running and holds the lock, any **other operation that would modify state** is **blocked** until the lock is released. The second process errors with a lock message; it does not queue silently and overwrite.

State locking stops two Terraform processes from writing the same state at the same time. Without a lock, two applies can read one serial, both write, and one writer's updates are lost. The state then disagrees with the infrastructure in a way that is painful to untangle.

Terraform acquires the lock automatically for operations that can write state: `apply`, `destroy`, `plan` (because refresh writes), `import`, `state mv`, `state rm`, and `refresh`. You do not turn locking on per command. If the backend supports locking, it is on.

If the lock is held, the second command stops with an error that includes a lock ID. It does not wait forever and then overwrite.

## Not every backend locks

**State locking is not guaranteed by all backends.** Before you use a backend in a **team** environment (shared remote state, multiple people or CI jobs), **verify on that backend’s documentation** that locking is supported and how to enable it (for example S3 + DynamoDB or `use_lockfile`, not a bare **http** backend without a lock protocol).

Remote storage alone does not imply locking. Two applies without a lock can still corrupt state.

## Which backends lock

Support is a **property of the backend**, documented on that backend's page.

- **local** locks with an OS file lock and writes `.terraform.tfstate.lock.info`.
- **s3** locks either with a DynamoDB table (`dynamodb_table`) or, in current Terraform, with an S3 lock file (`use_lockfile = true`).
- **HCP Terraform** and the `remote` / `cloud` integration lock on the remote side for you.
- Some backends, including a plain **http** backend, do not implement locking. Using one of those for a team means writes are not serialized.

A question that says "every backend locks" is too strong. A question that says "Terraform will not continue if it cannot acquire the lock" matches the documented behavior for backends that support it.

## A stuck lock and `terraform force-unlock`

Terraform **normally releases the lock automatically** when an operation **completes or fails**. You should not need to touch locks during day-to-day `plan` and `apply`.

A lock **sticks** when a process is killed mid-run (crash, `kill -9`, laptop sleep, CI agent terminated). The error on the next command includes a **lock ID**.

**`terraform force-unlock` is a last-resort command.** Use it only when **automatic release has failed** and you have confirmed **no other Terraform process** is still running against that state.

```bash
terraform force-unlock LOCK_ID
```

`force-unlock` does **not** verify that the holder is gone. If an apply is still writing state and you force-unlock, **two writers can proceed** and corrupt state. After a legitimate force-unlock, run **`terraform plan`**, read it carefully, then apply.

**Exam trap:** force-unlock is **not** the normal way to wait for another user’s apply to finish — wait for their run to end, or coordinate out of band. It is for **orphaned** locks only.

## What you should see locally

Start an apply in [06a](../06a-local-backend) and, on a second terminal, start another apply against the same directory while the first still holds the lock (the approval prompt is enough). The second command errors with a lock message. Confirm the first, let it finish, and the lock file disappears.
