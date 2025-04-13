namespace :users do
  desc "Migrate users from Sorcery to Devise in batches"
  task migrate_to_devise: :environment do
    batch_size = 100
    total_users = User.where(auth_system: 'sorcery').count
    processed = 0

    puts "Starting migration of #{total_users} users..."

    User.where(auth_system: 'sorcery').find_each(batch_size: batch_size) do |user|
      begin
        user.migrate_to_devise!
        processed += 1
        puts "Migrated user #{user.id} (#{processed}/#{total_users})"
      rescue => e
        puts "Failed to migrate user #{user.id}: #{e.message}"
      end
    end

    puts "Migration completed. Processed #{processed} users."
  end

  desc "Migrate the last user to Devise"
  task migrate_last_user: :environment do
    last_user = User.where(auth_system: 'sorcery').last
    if last_user
      begin
        puts "Migrating user #{last_user.id} (#{last_user.email})..."
        last_user.migrate_to_devise!
        puts "Successfully migrated user #{last_user.id} to Devise"
      rescue => e
        puts "Failed to migrate user #{last_user.id}: #{e.message}"
      end
    else
      puts "No Sorcery users found to migrate"
    end
  end
end 