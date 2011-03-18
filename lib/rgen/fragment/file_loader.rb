require 'digest'

module RGen

module Fragment

# The FileLoader loads fragments from files into a FragmentedModel.
#
# Using the load_from_files method, the files may be loaded initially as well as updated later on.
# In case of an update, new fragments will be created, unused fragments will be removed
# and changed fragments will be reloaded. Changes in a file are detected by means of a digest.
#
# The actual loading of fragments must be done by a proc registered with the constructor.
#
# Optionally, the loader can use a fragment cache to speed up loading.
#
class FileLoader

  # Create a file loader. Options:
  #
  #  :fragment_loader:
  #    a proc which receives a fragment and must populate it
  #
  #  :cache:
  #    a fragment cache to be used for loading
  #
  def initialize(model, options={})
    @model = model
    @fragment_loader = options[:fragment_loader]
    @cache = options[:cache]
    @digest_by_file = {}
  end

  # Load all the files provided and replace any files loaded before.
  # For new files this will add new model fragments. For removed or changed files this will 
  # remove or change existing model fragments.
  # 
  def load_from_files(files)
    raise "no fragment instantiator" unless @fragment_loader
    fragment_by_file = {}
    @model.fragments.each do |fragment|
      raise "fragments with identical location" if fragment_by_file[fragment.location] 
      fragment_by_file[fragment.location] = fragment
    end
    unused_files = fragment_by_file.keys
    files.each do |file|
      unused_files.delete(file)
      fragment = fragment_by_file[file]
      if fragment
        if !check_digest(file)
          @model.remove_fragment(fragment)
          @model.add_fragment(load_fragment(file))
        end
      else
        @model.add_fragment(load_fragment(file))
      end
    end
    unused_files.each do |file|
      fragment = fragment_by_file[file]
      @model.remove_fragment(fragment) if fragment
      @digest_by_file.delete(file)
    end
  end

  private

  def load_fragment(file)
    fragment = Fragment.new(file) 
    if @cache
      if @cache.load(fragment) == :invalid
        @fragment_loader.call(fragment)
        @cache.store(filfragmente)
      end
    else
      @fragment_loader.call(fragment)
    end
    update_digest(file)
  end

  def update_digest(file)
    @digest_by_file[file] = calc_digest(file) 
  end

  def check_digest(file)
    @digest_by_file[file] == calc_digest(file)
  end

  def calc_digest(file)
    sha1 = Digest::SHA1.new
    sha1.file(file)
    sha1.hexdigest
  end

end

end

end

