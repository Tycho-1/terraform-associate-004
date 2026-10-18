output "name" {
  description = "Generated pet name. Callers read this as module.pet.name."
  value       = random_pet.this.id
}

output "filename" {
  description = "File the module wrote."
  value       = local_file.unit.filename
}
