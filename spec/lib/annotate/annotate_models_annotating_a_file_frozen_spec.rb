# encoding: utf-8
require 'annotate/annotate_models'
require 'annotate/active_record_patch'
require 'active_support/core_ext/string'
require 'files'
require 'tmpdir'

RSpec.describe AnnotateModels do
  include AnnotateTestHelpers

  describe 'annotating a file' do
    before do
      @model_dir = Dir.mktmpdir('annotate_models')
      (@model_file_name, @file_content) = write_model 'user.rb', <<~EOS
        class User < ActiveRecord::Base
        end
      EOS

      @klass = mock_class(:users,
                          :id,
                          [
                            mock_column(:id, :integer),
                            mock_column(:name, :string, limit: 50)
                          ])
      @schema_info = AnnotateModels::SchemaInfo.generate(@klass, '== Schema Info')
      Annotate::Helpers.reset_options(Annotate::Constants::ALL_ANNOTATE_OPTIONS)
    end

    # TODO: Check out why this test fails due to test pollution
    describe 'frozen option' do
      it "should abort without existing annotation when frozen: true " do
        expect { annotate_one_file frozen: true }.to raise_error SystemExit, /user.rb needs to be updated, but annotate was run with `--frozen`./
      end

      it "should abort with different annotation when frozen: true " do
        annotate_one_file
        another_schema_info = AnnotateModels::SchemaInfo.generate(mock_class(:users, :id, [mock_column(:id, :integer)]), '== Schema Info')
        @schema_info = another_schema_info

        expect { annotate_one_file frozen: true }.to raise_error SystemExit, /user.rb needs to be updated, but annotate was run with `--frozen`./
      end

      it "should NOT abort with same annotation when frozen: true " do
        annotate_one_file
        expect { annotate_one_file frozen: true }.not_to raise_error
      end
    end
  end
end