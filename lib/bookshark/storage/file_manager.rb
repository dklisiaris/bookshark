require 'fileutils'
require 'json'

module FileManager

  DEFAULTS ||= {
    path: '',
    all: false,
    extension: '',
  }
  
  # Lists directories in current path or in path specified by options hash.
  #
  # ==== Attributes
  #
  # * +options+ - The options hash accepts options for a more specialized directory search operation.
  # 
  # ==== Options
  #
  # * +:path+ - The path where directory search will happen.
  # * +:all+ - If true, recursive search is enabled.
  #   
  def list_directories(options = {})
    options = DEFAULTS.merge(options)

    path = options[:path]
    all = options[:all]

    path = "#{path}/" unless path == '' or path.end_with?('/')
    path = path+'**/' if all
    

    Dir.glob("#{path}*/")
  end


  # Returns a list of all files in current directory or as specified in options hash.
  #
  # ==== Attributes
  #
  # * +options+ - The options hash accepts options for a more specialized file search operation.
  #
  # ==== Options
  #
  # * +:path+ - The path where file search will happen.
  # * +:extension+ - The extension of target files.
  # * +:all+ - If true, recursive search is enabled.
  #
  # ==== Examples
  #   
  #   files = list_files
  #   files = list_files path: 'html_pages'
  #   files = list_files path: 'raw_html_pages/2', extension:'html'
  #   files = list_files(path: 'ddc_pages', extension:'json', all:true).each do |file|
  #     file.do_something
  #   end
  #
  def list_files(options = {})  
    options = DEFAULTS.merge(options)

    path = options[:path]
    all = options[:all]
    extension = options[:extension]

    extension = ".#{extension}" unless extension == '' or extension.start_with?('.')    
    file_wildcard = "*#{extension}"

    path = "#{path}/" unless path == '' or path.end_with?('/')
    path = path+'**/' if all    

    Dir.glob("#{path}#{file_wildcard}")
  end

  # Saves some text/string to file.
  #
  # ==== Attributes
  #
  # * +path+ - The path to file(including filename) where content will be saved.
  # * +content+ - The text which will be saved to file.
  #
  # ==== Examples
  #   
  #   save_to('data_pages/categories/cat_15.txt', 'Some text')
  #  
  def save_to(path, content)   
    begin  
      dir = File.dirname(path)
      # Create a new directory (does nothing if directory exists or is a file)
      FileUtils.mkdir_p dir #unless File.dirname(path) == "."
            
      open(path, "w") do |f|
        f.write(content)
      end 

    rescue StandardError => e
      puts e
    end
  end



end

