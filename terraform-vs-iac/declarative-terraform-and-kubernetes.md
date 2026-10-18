# Declarative Terraform and declarative Kubernetes

Both systems take a description of what should exist and make the world match it. You do not write the create, update, and delete steps. The difference is when that matching runs, and where the record of "what we manage" lives.

This is the idea in [01a](../01-infrastructure-as-code/01a-what-is-iac), set next to Kubernetes. The exam does not ask for this comparison. The platforms do the split in practice: Terraform builds the cluster and the cloud around it, and Flux or Argo CD reconciles what runs inside. See [reference-platforms.md](../reference-platforms.md).

## The same shape

| | Terraform | Kubernetes |
|---|---|---|
| Desired state | `.tf` files | object `spec` in a manifest (YAML or JSON) |
| Record of reality | state file, written by Terraform | `status`, and the live objects in etcd |
| Diff | `terraform plan` | a controller comparing spec to the world; `kubectl diff` before an apply |
| Make it real | `terraform apply` | the controller's reconcile; `kubectl apply` writes the spec that controllers watch |
| Run it again | a second apply with no drift plans nothing | a second reconcile with spec already met changes nothing |
| Drift | the next plan shows it and apply puts the object back | a controller puts it back as soon as it notices, without a human starting a run |
| Dependencies | the graph, from references and `depends_on` | owner references, plus the order you apply documents that name each other |
| Reuse | modules | a chart, a kustomize overlay, or a controller that owns many objects from one spec |
| Source of truth in git | a CI job runs plan and apply | Flux or Argo CD applies from git and keeps reconciling |

A Terraform resource and a Kubernetes object are the same sentence. "An `aws_instance.web` with this type should exist." "A Deployment `web` with three replicas should exist." The AWS provider turns the first into API calls. The Deployment controller turns the second into a ReplicaSet and Pods.

## Where the mechanism splits

**Terraform reconciles when you run it.** `plan` and `apply` are a batch. Between runs, a deleted instance stays deleted. HCP Terraform drift detection can report that. It still takes an apply to fix it.

**Kubernetes reconciles in a loop.** Controllers watch the API. Delete a Pod that a Deployment still wants, and a new Pod appears without anyone running a command. That loop is the product. `kubectl apply` only stores the spec. The controllers do the work after that, continuously.

**Terraform keeps its own map.** State binds `aws_instance.web` to a real id. Kubernetes does not have a second file. The API object is the record. etcd holds spec and status. Field managers (server-side apply) record which client owns which field, so two appliers can share one object without a state file.

**Deleting the description does different things.** Remove a `resource` block and the next Terraform apply destroys the object, because it is in state. Delete a manifest from git and the cluster object remains until something prunes it. `kubectl delete -f` is that prune. Flux prunes only when pruning is turned on.

**The graph is explicit in Terraform and mostly emergent in Kubernetes.** Terraform will not create B before A if B's arguments reference A, and a cycle is an error. Kubernetes creates objects you applied. A Pod that names a missing ConfigMap still gets created and then fails until the ConfigMap appears. Owner references are how a parent object takes its children with it on delete. That is garbage collection, not a plan-time graph.

**Status is a separate channel in Kubernetes.** `spec` is what you want. `status` is what the controller observed. You do not write status in the manifest you keep in git. Terraform stores the attributes it last read in state, and the next plan treats those as the current world. There is no ongoing status document that other tools watch between applies.

**Scope.** Terraform's providers talk to many APIs: AWS, Azure, GCP, DNS, GitHub, Kubernetes. One state file can track all of them. Kubernetes is one API. CRDs extend that API, and a controller reconciles the new kind. **Crossplane** is that pattern pointed at cloud APIs: provider controllers create VPCs, buckets, and databases from CRs instead of from `terraform apply`. Extended comparison (state/backend, reconciliation, when to use which): [Crossplane vs Terraform](crossplane/crossplane-vs-terraform.md).

## What is stronger where

**Terraform is the better fit for infrastructure that has no controller.** VPC, IAM, DNS, a database, the cluster itself. Those APIs accept a call and then sit still. Terraform's plan is the review: the diff is visible before anything changes, and the blast radius is the resources in that state. A saved plan (`terraform plan -out`) is a change you can approve and apply unchanged.

**Kubernetes is the better fit for things that must heal while you are not looking.** Replicas, rollouts, endpoints, a Pod that died. The Deployment controller is supposed to act without a pipeline run. Waiting for the next `terraform apply` to recreate a crashed process is the wrong loop.

**Use each at its boundary.** Managing Deployments, Services, and application config through the Terraform Kubernetes or Helm provider stores those objects in Terraform state and updates them only on apply. The cluster's own controllers are already doing that job, continuously, and the two writers drift. The reference platforms stop Terraform at the cluster: the cloud and the cluster are Terraform, and Flux or Argo CD owns what runs inside.

**GitOps is Kubernetes taking Terraform's idea and running it in a loop.** A commit changes the desired spec. The reconciler applies it and keeps applying it. Terraform CI (plan on the pull request, apply on merge) is the same idea in batch form, which is what you want when the change is a network or a database and you want a human to see the destroy lines first.

On HCP Terraform, **health assessments** (scheduled drift detection and re-running `check` blocks) add “is reality still what we expect?” **without** auto-reconcile — alerting between applies, not a controller loop. [8b — Health assessments](../08-hcp-terraform/08b-collaboration-governance#health-assessments).

Neither language is "more declarative." Both describe the end state. Terraform is the stronger change-review tool for cloud APIs. Kubernetes is the stronger runtime for workloads that should converge on their own.
