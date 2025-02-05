Describe 'Server Deployment Tests' {
    It 'should validate server deployment' {
        $result = Invoke-Expression -Command './deploy-server.ps1'
        $result | Should -Be 'Deployment Successful'
    }
}