require 'test_helper'

class ZipFileExtractTest < MiniTest::Test
  include CommonZipFileFixture
  EXTRACTED_FILENAME = 'test/data/generated/extEntry'
  ENTRY_TO_EXTRACT, *REMAINING_ENTRIES = TEST_ZIP.entry_names.reverse

  def setup
    super
    ::File.delete(EXTRACTED_FILENAME) if ::File.exist?(EXTRACTED_FILENAME)
  end

  def test_extract
    assert_extract(EXTRACTED_FILENAME)
  end

  def test_extract_nested_file
    assert_extract('test/data/generated/a/b/c/extEntry')
  end

  def test_extract_exists
    writtenText = 'written text'
    ::File.open(EXTRACTED_FILENAME, 'w') { |f| f.write(writtenText) }

    assert_raises(::Zip::DestinationFileExistsError) do
      ::Zip::File.open(TEST_ZIP.zip_name) do |zf|
        zf.extract(zf.entries.first, EXTRACTED_FILENAME)
      end
    end
    File.open(EXTRACTED_FILENAME, 'r') do |f|
      assert_equal(writtenText, f.read)
    end
  end

  def test_extract_exists_overwrite
    writtenText = 'written text'
    ::File.open(EXTRACTED_FILENAME, 'w') { |f| f.write(writtenText) }

    gotCalledCorrectly = false
    ::Zip::File.open(TEST_ZIP.zip_name) do |zf|
      zf.extract(zf.entries.first, EXTRACTED_FILENAME) do |entry, extractLoc|
        gotCalledCorrectly = zf.entries.first == entry &&
                             extractLoc == EXTRACTED_FILENAME
        true
      end
    end

    assert(gotCalledCorrectly)
    ::File.open(EXTRACTED_FILENAME, 'r') do |f|
      assert(writtenText != f.read)
    end
  end

  def test_extract_non_entry
    zf = ::Zip::File.new(TEST_ZIP.zip_name)
    assert_raises(Errno::ENOENT) { zf.extract('nonExistingEntry', 'nonExistingEntry') }
  ensure
    zf.close if zf
  end

  def test_extract_non_entry_2
    outFile = 'outfile'
    assert_raises(Errno::ENOENT) do
      zf = ::Zip::File.new(TEST_ZIP.zip_name)
      nonEntry = 'hotdog-diddelidoo'
      assert(!zf.entries.include?(nonEntry))
      zf.extract(nonEntry, outFile)
      zf.close
    end
    assert(!File.exist?(outFile))
  end

  private

  def assert_extract(extracted_filename)
    ::Zip::File.open(TEST_ZIP.zip_name) do |zf|
      zf.extract(ENTRY_TO_EXTRACT, extracted_filename)

      assert(File.exist?(extracted_filename))
      AssertEntry.assert_contents(extracted_filename,
                                  zf.get_input_stream(ENTRY_TO_EXTRACT) { |is| is.read })

      ::File.unlink(extracted_filename)

      entry = zf.get_entry(ENTRY_TO_EXTRACT)
      entry.extract(extracted_filename)

      assert(File.exist?(extracted_filename))
      AssertEntry.assert_contents(extracted_filename,
                                  entry.get_input_stream { |is| is.read })
    end
  end
end
