class GmlObject

  attr_accessor :tag

  def initialize(**opts)
    self.tag = opts[:tag]
    # raise "GmObject requires :tag_id" if self.tag_id.blank?
  end

  def tag_id
    tag.try(:id)
  end

  def self.file_dir
    "#{Rails.root}/public/data"
  end

  def filename
    return nil if tag.try(:id).blank?
    "#{self.class.file_dir}/#{tag.id}.gml"
  end

  def s3_file_key
    "gml/#{tag_id}.gml"
  end

  # TODO do we want to partition IPFS folders based on id, like we do locally?
  # e.g. id 501404 becomes approximately dir/501/404
  IPFS_FOLDER_NAME = "000000book_dev"

  def data
    # Rails.logger.debug "*** GmlObject #data..."
    @data ||= read_from_disk
  end

  def data=(args)
    Rails.logger.debug "*** GmlObject #data=, #{args.try(:length)} bytes"
    @data = args
  end

  def valid?
    # FIXME
    true
  end

  def self.read_all_cached_gml
    Dir.glob("#{file_dir}/*.gml").each do |path|
      id = path.match(/.+\/(.+)\.gml/)[1]
      tag = Tag.find_by_id(id)
      if tag.nil?
        Rails.logger.warn "Could not find Tag #{id} for path=#{path.inspect}, skipping"
        next
      end

      if tag.gml_object.blank?
        Rails.logger.info "No GmlObject for Tag #{id}, creating"
        tag.send(:build_gml_object) # sorry
        tag.send(:save_gml_object) # really I mean it
      end
    end
  end

  def save
    raise "Oh no you called GmlObject#save"
  end

  def save!
    # raise "Oh no you called GmlObject#save!"
    store_on_disk
    # store_on_s3
    # store_on_ipfs
  end

  def exists_on_disk?
    File.exist?(filename)
  end

  def store_on_disk
    puts "GmlObject.store_on_disk data[0..100]=#{data[0..100]}"

    if filename.blank?
      Rails.logger.error "Cannot store GmlObject(tag_id=#{tag_id}) on disk, invalid filename. tag_id=#{self.tag_id.inspect} filename=#{filename.inspect}"
      raise "Filename is blank, cannot store on disk"
    end

    unless Dir.exist?(self.class.file_dir)
      FileUtils.mkdir(self.class.file_dir)
    end

    Rails.logger.info "GmlObject(tag_id=#{tag_id}).store_on_disk filename=#{filename} ..."

    File.open(filename, 'w+') do |file|
      file.write(data)
    end
    return true
  end

  def read_from_disk
    return nil if filename.blank?
    return nil unless File.exists?(filename)
    data = File.read(filename)
    Rails.logger.info "GmlObject(tag_id=#{tag_id}).read_from_disk filename=#{filename} => #{data.length} bytes"
    return data
  end

  def s3_bucket_name
    ENV['S3_BUCKET']
  end

  def s3
    raise "No S3_BUCKET defined" if s3_bucket_name.blank?
    @s3 ||= Aws::S3::Resource.new
  end

  def s3_object
    puts s3_file_key
    @s3_object ||= S3_BUCKET.object(s3_file_key)
  end

  def store_on_s3
    raise "No local GML file to upload (#{filename})" if filename.blank?
    raise "Local GML file is empty, not uploading" if read_from_disk.blank?

		# directly upload from disk...
		# assumes we have stored on this local disk
		# obj.write()
    s3_object.upload_file(filename)

		# # string data
		# obj.put(body: 'Hello World!')

		# # IO object
		# File.open('source', 'rb') do |file|
	 	#		obj.put(body: file)
		# end
  end

  def read_from_s3
    file = s3_object.get
    file.body.read
  end

  # TODO test that daemon is running or use infura node as fallback ^_^
  def ipfs
    @ipfs ||= IPFS::Client.default
  end

  def store_on_ipfs
    ret = ipfs.add File.open(filename)
    Rails.logger.debug ret.pretty_inspect
    added_file_hash = ret.hashcode

    Rails.logger.info "IPFS: added tag ##{self.tag_id} (#{size} bytes) to IPFS => #{added_file_hash}"

    self.update_attribute(:ipfs_hash, added_file_hash)
    self.update_attribute(:size, size) # FIXME should be setting on-create and treating as immutable

    added_file_hash
  end

  def open_ipfs_file
    return if self.ipfs_hash.blank?
    `open http://ipfs.io/ipfs/#{self.ipfs_hash}`
  end

  def read_from_ipfs
    raise "No ipfs_hash for this Tag #{self.tag_id}" if self.ipfs_hash.blank?
    ipfs.cat(self.ipfs_hash)
  end

end
