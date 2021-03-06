namespace :gml_objects do

  desc "Save all GmlObjects to disk"
  task :save_to_disk => :environment do
    Tag.find_each do |tag|
      obj = tag.gml_object
      puts "#{obj.id} (#{obj.tag_id}) data.length=#{obj.data.length} ..."
      obj.store_on_disk
    end
  end

  desc "Store all GmlObjects on IPFS"
  task :save_to_ipfs => :environment do
    GmlObject.ensure_ipfs_is_running!
    Tag.find_each do |tag|
      obj = tag.gml_object
      res = obj.store_on_ipfs
      puts "Tag #{tag.id} (#{tag.size} bytes): #{res.inspect} => #{tag.ipfs_hash.inspect}"
      sleep 1
    end
  end

  desc "Generate empty GmlObjects for all Tags that don't have them"
  task :fix_missing => :environment do
    Tag.find_each do |tag|
      next unless tag.gml_object.nil?
      tag.send(:build_gml_object)
      tag.send(:save_gml_object)
    end
  end

end

