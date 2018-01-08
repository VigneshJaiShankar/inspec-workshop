if os.debian?
control "mongrel2-01" do                                
  impact 1.0                                          
  title "Mongrel2 service"                                 
  desc "Checking whether Mongrel2 service is running" 
  describe service('runit') do                                              #checking mongrel2 service status
    it { should be_enabled }                                                  
    it { should be_installed }
    it { should be_running }
  end
end

control "mongrel2-02" do
  impact 1.0
  title "Mongrel2 Requirements"
  desc "Checking for mongrel2 requirements"
  describe package('libzmq5') do                                            #cheking whether libzmq package is installed
     it { should be_installed }
  end
  
  describe package('libsqlite3-0') do                                       #checking whether libsqlite package is installed
     it { should be_installed }
  end
  
  if command('m2sh version').stdout == "Mongrel2/1.11.0\n" then             #if mongrel2 version is 1.11.0
  describe package('libmbedtls10') do                                       #then libmbedtls package should be installed
     it { should be_installed }
  end
  
  elsif command('m2sh version').stdout == "Mongrel2/1.9.3\n" then           #if mongrel2 version is 1.9.3
  describe package('libpolarssl5') do                                       #then libpolarssl package should be installed
     it { should be_installed }
  end
  end
end

control "mongrel2-03" do
  impact 1.0
  title "Mongrel2 user"
  desc "Checking user parameters"
  describe user('mongrel2') do                                              #checking user related properties
     it { should exist }
     its('uid') { should eq 121 }
     its('gid') { should eq 65534 }
     its('group') { should eq 'nogroup' }
     its('home') { should eq '/var/run/mongrel2' }
     its('shell') { should eq '/bin/false' }
  end                                       
 
  describe passwd.users('mongrel2') do                                       #checking passwd file
     its('uids') { should eq ['121'] }
     its('passwords') { should_not be 'x'}
  end
end

control "mongrel2-04" do
  impact 1.0
  title "Port checking"
  desc "Checking ports and protocols associated with it"
  describe port(7980) do                                                      #port checking
     it { should be_listening }
     its('protocols') { should cmp 'tcp' }
     its('protocols') { should cmp 'http'}
     its('protocols') { should include 'ftp'}
     its('processes') { should include 'ssh'} 
  end  
  
  describe host('localhost', port: 7980, protocol: 'tcp') do                  #checking host availability
     it { should be_reachable }
     it { should be_resolvable }
  end  
  
  describe ssl(port: 7980) do                                                 #checking whether ssl is enabled on port:7980 
     it { should be_enabled }
  end
  
  describe firewalld do                                                       #examining firewalld
     it { should be_installed }
     it { should be_running }
     it { should have_port_enabled_in_zone('7980/tcp', 'public') }            #checking whether firewall is enabled for port:7980
  end
end

control "mongrel2-05" do
  impact 1.0
  title "Access Permissions"
  desc "Checking file access permissions"
  describe directory('/etc/mongrel2') do                                      #checking mongrel2 directory access permissions
     it { should be_owned_by 'mongrel2' }
     it { should be_grouped_into 'root' }
     it { should be_readable.by('owner') }
     it { should be_writable.by('owner') }
     it { should be_executable.by('owner') }
     it { should be_readable.by('group') }
     it { should_not be_writable.by('group') }
     it { should_not be_executable.by('group') }
     it { should be_readable.by('others') }
     it { should_not be_writable.by('others') }
     it { should_not be_executable.by('others') }
  end

  describe file('/etc/mongrel2/mongrel2.conf') do                             #checking mongrel2.conf file access permissions
     it { should be_owned_by 'mongrel2' }
     it { should be_grouped_into 'root' }
     it { should be_readable.by('owner') }
     it { should be_writable.by('owner') }
     it { should_not be_executable.by('owner') }
     it { should be_readable.by('group') }
     it { should_not be_writable.by('group') }
     it { should_not be_executable.by('group') }
     it { should_not be_readable.by('others') }
     it { should_not be_writable.by('others') }
     it { should_not be_executable.by('others') }
  end

  describe directory('/etc/mongrel2/certs') do
     it { should be_owned_by 'mongrel2' }
     it { should be_readable.by('owner') }
     it { should_not be_executable.by('owner') }
     it { should_not be_readable.by('others') }
     it { should_not be_writable.by('others') }
     it { should_not be_executable.by('others') } 
  end
  
  describe shadow.users('mongrel2') do
     its('passwords') { should_not eq ['*'] }
     its('min_days') { should eq ['0'] }                                                        #mongrel2:*:17535:0:99999:7:::
     its('max_days') { should eq ['99999'] }
     its('warn_days') { should eq ['7'] }
  end    
end                                                                       

control "mongrel2-06" do
  impact 1.0
  title "Mongrel2 Configuration"
  desc "Parsing mongrel2.conf file"
  options = {
    assignment_regex: /^\s*([^=]*?)\s*=\s*(.*?)\s*$/ ,                                          
    multiple_values: true,
    comment_char: '#'
  }                                                                                        
   
  describe file('/etc/mongrel2/mongrel2.conf') do                                        #parsing configuration file
     it { should be_owned_by 'mongrel2' }
     its('mode') { should eq '0644' }
     its('content') { should match (%r{uuid='default_7980'}) }
     its('content') { should match (%r{access_log='/var/log/mongrel2/access_7980.log'}) }
     its('content') { should match (%r{error_log='/var/log/mongrel2/error_7980.log'}) }
     its('content') { should match (%r{pid_file='/var/run/mongrel2/mongrel2_7980.pid'}) }
     its('content') { should match (%r{control_port='ipc:///var/run/mongrel2/control_7980'}) }
     its('content') { should match (%r{default_host='default'}) }
     its('content') { should match (%r{port=7980}) }
     its('content') { should match (%r{hosts=\[default_host\]}) }
     its('content') { should match (%r{'certdir': '/etc/mongrel2/certs/'}) }
  end                        
                 
  #describe parse_config_file('/etc/mongrel2/mongrel2.conf',options) do
  #   its('port') {should cmp '7980,'}
  #   its('control_port') {should cmp '\'ipc:///var/run/mongrel2/control_7980\','}
  #end
end
end
