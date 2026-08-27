output "ngwaf_workspace_id" {
  value       = fastly_ngwaf_workspace.ngwaf_workspace.id
  description = "ID of the NGWAF workspace used by delivery services."
}