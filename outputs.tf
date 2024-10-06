output "kafka_status" {
  value = helm_release.kafka.status
}

output "postgresql_status" {
  value = helm_release.postgresql.status
}
