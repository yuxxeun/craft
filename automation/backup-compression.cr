require "compress/gzip"
require "file"
require "time"

class DatabaseBackup
  property db_name : String
  property backup_dir : String
  property retention_days : Int32

  def initialize(@db_name, @backup_dir, @retention_days = 7)
  end

  def execute
    puts "🗄️  Starting backup for: #{@db_name}"
    
    timestamp = Time.local.to_s("%Y%m%d_%H%M%S")
    backup_file = "#{@backup_dir}/#{@db_name}_#{timestamp}.sql"
    compressed_file = "#{backup_file}.gz"

    # Dump database
    dump_cmd = "pg_dump #{@db_name} > #{backup_file}"
    system(dump_cmd)

    # Compress dengan Gzip
    File.open(backup_file, "r") do |input|
      Compress::Gzip::Writer.open(compressed_file) do |gzip|
        IO.copy(input, gzip)
      end
    end

    # Hapus file SQL asli
    File.delete(backup_file)

    file_size = File.size(compressed_file).to_f / (1024 * 1024)
    puts "✅ Backup completed: #{compressed_file}"
    puts "📦 Size: #{file_size.round(2)} MB"

    # Cleanup old backups
    cleanup_old_backups
  end

  def cleanup_old_backups
    cutoff_time = Time.local - Time::Span.new(days: @retention_days)
    deleted_count = 0

    Dir.glob("#{@backup_dir}/#{@db_name}_*.sql.gz").each do |file|
      if File.info(file).modification_time < cutoff_time
        File.delete(file)
        deleted_count += 1
        puts "🗑️  Deleted old backup: #{file}"
      end
    end

    puts "🧹 Cleaned up #{deleted_count} old backups"
  end
end

# Jalankan backup
backup = DatabaseBackup.new(
  db_name: "production_db",
  backup_dir: "/backups/postgresql",
  retention_days: 7
)

backup.execute