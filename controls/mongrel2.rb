control "mongrel2-01" do                                
  impact 1.0                                          
  title " "                                 
  desc "" 
  describe package('libzmq5') do
      it {should be_installed}
  end
  describe package('libsqlite3-0') do
      it {should be_installed}
  end
  describe service('runit') do
     it { should be_enabled }
     it { should be_installed }
     it { should be_running }
  end
 describe port(7980) do
     it {should be_listening}
     its('processes') {should cmp 'libzmq5'}
 end                                                
end

