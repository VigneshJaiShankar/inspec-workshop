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
    describe package('libmbedtls10') do                                      #then libmbedtls package should be installed
       it { should be_installed }
    end 
  
   elsif command('m2sh version').stdout == "Mongrel2/1.9.3\n" then           #if mongrel2 version is 1.9.3
    describe package('libpolarssl5') do                                      #then libpolarssl package should be installed
       it { should be_installed }
    end
   end
 end

 control "mongrel2-03" do
   impact 1.0
   title "Mongrel2 user"
   desc "Checking user parameters"
   File.open('/etc/passwd', 'r').each do |str|
    if str.include? "mongrel2"                                                #ruby code for fetch userid,pawssword,groupid from /etc/passwd file 
       user=str.split(":")
       $password=user[1]
       $userid=user[2].to_i
       $groupid=user[3].to_i
    end
   end
   describe user('mongrel2') do                                               #checking user related properties available in /etc/passwd 
      it { should exist }
      its('uid') { should eq $userid }
      its('gid') { should eq $groupid }
      its('group') { should eq 'nogroup' }
      its('home') { should eq '/var/run/mongrel2' }
      its('shell') { should eq '/bin/false' }
   end                                       
 
   describe passwd.users('mongrel2') do                                       #checking passwd file available at /etc/passwd
      its('uids') { should eq [$userid.to_s] }
      its('passwords') { should_not be 'x'}
   end
 end

 control "mongrel2-04" do
   impact 1.0
   title "Port checking"
   desc "Checking ports and protocols associated with it"
   describe port(7980) do                                                     #port and protocols checking
      it { should be_listening }
      its('protocols') { should cmp 'tcp' }                                   
      its('protocols') { should cmp 'http'}
      its('protocols') { should include 'ftp'}
      its('processes') { should include 'ssh'} 
   end  
  
   describe host('localhost', port: 7980, protocol: 'tcp') do                 #checking host availability
      it { should be_reachable }
      it { should be_resolvable }
   end  
  
   describe ssl(port: 7980) do                                                #checking whether ssl is enabled on port:7980 
      it { should be_enabled }
   end
  
   describe firewalld do                                                      #examining firewalld
      it { should be_installed }
      it { should be_running }
      it { should have_port_enabled_in_zone('7980/tcp', 'public') }           #checking whether firewall is enabled for port:7980
   end
 end

 control "mongrel2-05" do
   impact 1.0
   title "Access Permissions"
   desc "Checking file access permissions"
   describe directory('/etc/mongrel2') do                                      #checking mongrel2 directory access permissions located at /etc
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

   describe file('/etc/mongrel2/mongrel2.conf') do                             #checking mongrel2.conf file access permissions located at /etc
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

   describe directory('/etc/mongrel2/certs') do                                #checking certs directory access permissions located at /etc/mongrel2
      it { should be_owned_by 'mongrel2' }
      it { should be_readable.by('owner') }
      it { should be_executable.by('owner') }
      it { should_not be_readable.by('others') }
      it { should_not be_writable.by('others') }
      it { should_not be_executable.by('others') } 
   end
   
     
   File.open('/etc/shadow', 'r').each do |str|
    if str.include? "mongrel2"                                                 #ruby code for fetch pawssword,mindays,maxdays,warndays from /etc/passwd file 
       user=str.split(":")
       $password=user[1]
       $mindays=user[3]
       $maxdays=user[4]
       $warndays=user[5]
    end
   end
   describe shadow.users('mongrel2') do                                        #checking shadow file for mongrel2 user  
      its('passwords') { should_not eq [$password] }
      its('min_days') { should eq [$mindays] }                                                        
      its('max_days') { should eq [$maxdays] }
      its('warn_days') { should eq [$warndays] }
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
   
   describe file('/etc/mongrel2/mongrel2.conf') do                                 #parsing configuration file
      it { should be_owned_by 'mongrel2' }
      its('mode') { should eq 420 }
      its('content') { should match (%r{uuid='default_7980'}) }
      its('content') { should match (%r{use_ssl=1}) }                              #include this inside server_7980 in mongrel2.conf if ssl configurations are required
      its('content') { should match (%r{access_log='/var/log/mongrel2/access_7980.log'}) }
      its('content') { should match (%r{error_log='/var/log/mongrel2/error_7980.log'}) }
      its('content') { should match (%r{pid_file='/var/run/mongrel2/mongrel2_7980.pid'}) }
      its('content') { should match (%r{control_port='ipc:///var/run/mongrel2/control_7980'}) }
      its('content') { should match (%r{default_host='default'}) }
      its('content') { should match (%r{port=7980}) }
      its('content') { should match (%r{hosts=\[default_host\]}) }
      its('content') { should match (%r{'certdir': '/etc/mongrel2/certs/'}) }
      its('content') { should match (%r{'ssl_ciphers': 'SSL_RSA_RC4_128_SHA'}) }    #include this inside settings in mongrel2.conf if ssl congigurations are required
   end                        
 end

 control "mongrel2-07" do
   impact 1.0
   title "Mongrel2 performance settings"
   desc"Mongrel2 server can be configured to obtain high performance output by including the respective settings and by setting their values based on our system"
   describe file('/etc/mongrel2/mongrel2.conf') do
      its('content') { should match (%r{limits.buffer_size=2048}) }                #Internal IO buffers, used for things like proxying and handling requests.The average is 400-600 bytes.Maximum size is 4096
      
      its('content') { should match (%r{limits.client_read_retries=5}) }           #Number of times it will attempt to read a complete HTTP header from a client. This prevents attacks where a client trickles an incomplete request at you until you run out of resources.Max value is 5
      
      its('content') { should match (%r{limits.connection_stack_size=32768}) }     #Size of the stack used for connection coroutine.Values should be given based on how many connections our RAM can.Max is 32768
      
      its('content') { should match (%r{limits.dir_max_path=256}) }                #Max path length you can set for Dir handlers.
      
      its('content') { should match (%r{limits.dir_send_buffer=16 * 1024}) }       #Maximum buffer used for file sending when we need to use one.
      
      its('content') { shoould match (%r{limits.handler_stack=100 * 1024}) }       #The stack frame size for any Handler tasks.Set this based on what our system can handle.
      
      its('content') { should match (%r{limits.handler_targets=128}) }             #The maximum number of connection IDs a message from a Handler may target. It should not be set to really high values.

      its('content') { should match (%r{limits.proxy_read_retries=100}) }          #The number of read attempts Mongrel2 should make when reading from a backend proxy.

       its('content') { should match (%r{limits.proxy_read_retry_warn=10}) }       #This is the threshold where you get a warning that a particular backend is having performance problems, useful for spotting potential errors before they become a problem.
      
      its('content') { should match (%r{superpoll.max_fd=10 * 1024}) }             #Maximum possible open files. Do not set this above 64 * 1024, and expect it to take a bit while Mongrel2 sets up constant structures.
      
      its('content') { should match (%r{upload.temp_store=None}) }                 #If we want large requests to reach our handlers, then this can  be set to a directory they can access, and make sure they can handle it.
      
      its('content') { should match (%r{zeromq.threads=1}) }                       #Number of 0MQ IO threads to run.We may experience thread bugs in 0MQ sometimes if the value of this is high.
   end
 end
end
