Puppet::Type.type(:virt).provide :lxc do
    desc 'Manages Linux containers'

    commands :lxccreate   => 'lxc-create',
             :lxcdestroy  => 'lxc-destroy',
             :lxcclone    => 'lxc-clone',
             :lxcinfo     => 'lxc-info',
             :lxcstart    => 'lxc-start',
             :lxcstop     => 'lxc-stop',
             :lxcfreeze   => 'lxc-freeze',
             :lxcunfreeze => 'lxc-unfreeze'

    has_features :cloneable
    has_features :backingstore
    has_features :initial_config

    def install
      args = ['-n', @resource[:name]]
      args.push('-t', @resource[:os_template])
      if !@resource[:backingstore].nil?
         args.push('-B', @resource[:backingstore])
      end
      if !@resource[:configfile].nil?
         args.push('-f', @resource[:configfile])
      end
      if !@resource[:clone].nil?
        clone
      else
        lxccreate(*args)
      end
    end

    def clone
      args = ['-o', @resource[:clone]]
      args.push('-n', @resource[:name])
      if @resource[:snapshot]
         args.push('-s')
      end
      lxcclone(*args)
    end

    def setpresent
      install
    end

    def start
      if !exists?
        install
      elsif status == :freeze
        unfreeze
      end
      lxcstart('-n', @resource[:name], '-d')
    end

    def stop
      if !exists?
        install
      end
      lxcstop('-n', @resource[:name])
    end

    def freeze
      if !exists?
        install
        start
      end
      lxcfreeze('-n', @resource[:name])
    end

    def unfreeze
      lxcunfreeze('-n', @resource[:name])
    end

    def destroy
      lxcdestroy('-n', @resource[:name], '-f')
    end

    # FIXME: This path should be configurable
    def exists?
      if File.exists? "/var/lib/lxc/#{@resource[:name]}"
        true
      else
        false
      end
    end

    # lxc-info returns stopped if the container
    # doesn't exist
    def status
      stat = lxcinfo('-n', @resource[:name])
      if !exists?
        :absent
      elsif exists? and resource[:ensure].to_s == 'installed'
        :installed
      elsif stat.include?("STOPPED")
        return :stopped
      else
        stat = stat.split(" ")[1].downcase.to_sym
      end
    end

    # FIXME
    def cpus
      1
    end

end

