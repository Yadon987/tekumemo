namespace :guest do
  desc "Check for guest users and orphaned data"
  task check: :environment do
    puts "=== 1. Suspicious User Accounts ==="
    users = GuestCleanupService.check_guests

    if users.exists?
      users.find_each do |u|
        puts "User ID: #{u.id}, Name: #{u.name}, Email: #{u.email}, Role: #{u.role}"
      end
    else
      puts "No suspicious user accounts found."
    end

    puts "\n=== 2. Orphaned Data (Records without valid User) ==="
    counts = GuestCleanupService.count_orphans
    counts.each do |key, value|
      puts "Orphaned #{key.to_s.humanize}: #{value}"
    end
  end

  desc "Clean up orphaned data"
  task clean_orphans: :environment do
    puts "Cleaning up orphaned data..."
    start_counts = GuestCleanupService.count_orphans
    deleted = GuestCleanupService.clean_orphans!
    
    puts "Deleted records:"
    deleted.each do |key, value|
      puts "- #{key}: #{value}"
    end
    puts "Done."
  end

  desc "Clean up actual guest users (strict check)"
  task clean_users: :environment do
    puts "Searching for guest users to delete..."
    deleted_count = GuestCleanupService.clean_users!
    
    if deleted_count == 0
      puts "No guest users found matching the strict criteria."
    else
      puts "Successfully deleted #{deleted_count} guest users."
    end
  end
end
