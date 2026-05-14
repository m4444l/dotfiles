#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "thor"
end

class Link < Thor
  include Thor::Actions

  default_command :link

  def self.exit_on_failure? = true

  desc "link", "Create symlinks for dotfiles in home directory"
  option :dry_run, type: :boolean, default: false, desc: "Show actions without changing the filesystem"
  option :force, type: :boolean, default: false, desc: "Overwrite existing files or symlinks"
  def link
    require "fileutils"
    require "find"
    require "set"

    root = File.join(__dir__, "files")
    broken_symlinks = Set.new

    process(root, root, broken_symlinks)
    find_broken_home_symlinks(root, broken_symlinks)
    find_broken_symlinks(root, target_dirs(root), broken_symlinks)
  end

  private

    def process(dir, root, broken_symlinks)
      same_dir = dir == root

      Dir
        .children(dir)
        .each do |entry|

        full_path = File.join(dir, entry)

        if File.directory?(full_path)
          if entry.start_with?("@")
            link_entry(full_path, entry.delete_prefix("@"), dir, root, same_dir, broken_symlinks)
          else
            process(full_path, root, broken_symlinks)
          end
          next
        end

        link_entry(full_path, entry, dir, root, same_dir, broken_symlinks)
      end
    end

    def link_entry(source, target_name, dir, root, same_dir, broken_symlinks)
      target_file =
        same_dir ?
          target_name :
          dir
            .delete_prefix(root)
            .delete_prefix("/")
            .then { File.join(_1, target_name) }

      target     = File.join(ENV["HOME"], ".#{target_file}")
      target_dir = File.dirname(target)

      case
      when same_dir
        # No parent directories to create.
      when Dir.exist?(target_dir)
        if options[:dry_run]
          say "Would skip #{target_dir} (already exists)", :yellow
        end
      when options[:dry_run]
        say "Would create directory #{target_dir}", :blue
      else
        FileUtils.mkdir_p(target_dir)
        say "Created directory #{target_dir}", :green
      end

      if File.exist?(target) || File.symlink?(target)
        if broken_symlink?(target)
          broken_symlinks << target
          say "Found broken symlink #{target} -> #{File.readlink(target)}", :red
        end

        if options[:dry_run]
          action = options[:force] ? "force remove" : "skip"
          say "Would #{action} #{target} (already exists)", :blue
          return
        end

        unless options[:force]
          say "Skipping #{target} (already exists)", :yellow
          return
        end

        FileUtils.rm_f(target)
        say "Removed #{target}", :yellow
      end

      if options[:dry_run]
        say "Would link #{source} -> #{target}", :green
      else
        File.symlink(source, target)
        say "Linked #{source} -> #{target}", :green
      end
    end

    def target_dirs(root)
      collect_target_dirs(root, root).uniq
    end

    def collect_target_dirs(dir, root)
      Dir
        .children(dir)
        .flat_map do |entry|

        full_path = File.join(dir, entry)

        if File.directory?(full_path)
          if entry.start_with?("@")
            target_dir = File.dirname(target_for_at_dir(full_path, root))
            (target_dir == ENV["HOME"] ? [] : [target_dir])
          else
            collect_target_dirs(full_path, root)
          end
        elsif File.file?(full_path) || File.symlink?(full_path)
          target_dir = File.dirname(target_for(full_path, root))
          (target_dir == ENV["HOME"] ? [] : [target_dir])
        else
          []
        end
      end
    end

    def target_for_at_dir(path, root)
      relative_path = path
        .delete_prefix(root)
        .delete_prefix("/")
        .then { File.join(File.dirname(_1), File.basename(_1).delete_prefix("@")) }
        .delete_prefix("./")
      File.join(ENV["HOME"], ".#{relative_path}")
    end

    def find_broken_home_symlinks(root, already_reported)
      Dir
        .children(ENV["HOME"])
        .map { File.join(ENV["HOME"], _1) }
        .each do |path|
        next unless broken_symlink?(path)
        next if already_reported.include?(path)
        next unless link_points_into?(path, root)

        say "Found broken symlink #{path} -> #{File.readlink(path)}", :red
        already_reported << path
      end
    end

    def find_broken_symlinks(root, dirs, already_reported)
      dirs
        .select { Dir.exist?(_1) }
        .each do |dir|
        Find.find(dir, ignore_error: true) do |path|
          Find.prune if File.directory?(path) && File.symlink?(path)
          next unless broken_symlink?(path)
          next if already_reported.include?(path)
          next unless link_points_into?(path, root)

          say "Found broken symlink #{path} -> #{File.readlink(path)}", :red
          already_reported << path
        end
      end
    end

    def broken_symlink?(path)
      File.symlink?(path) && !File.exist?(path)
    end

    def link_points_into?(path, root)
      destination = File.readlink(path)
      expanded =
        if destination.start_with?("/")
          destination
        else
          File.expand_path(destination, File.dirname(path))
        end

      expanded == root || expanded.start_with?("#{root}/")
    end

    def target_for(path, root)
      relative_path = path.delete_prefix(root).delete_prefix("/")
      File.join(ENV["HOME"], ".#{relative_path}")
    end
end

Link.start(ARGV)
