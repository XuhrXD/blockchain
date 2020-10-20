pragma solidity ^0.5.0;

contract DAOInterface {
    
    struct Proposal {
        string description;
        uint voteyes;
        uint voteno;
        bool issealed;
        mapping(address => bool)  yes;
        mapping(address => bool)  no;
        
        // Number of Tokens in favor of the proposal
    }
    
    // Proposals to spend the DAO's ether
    mapping(uint => Proposal) public proposals;
    mapping(address => bool) public investors;
    mapping (address => uint256) public balances;
    mapping(address =>mapping(uint => bool)) public votes;
    uint256 public totalBalance;
    uint256 public proposalIndex;
    uint256 public valuation;
    address public curator;
    
}

contract DAO is DAOInterface{

    constructor() public{
        curator = msg.sender;
        totalBalance = 0;
        proposalIndex = 0;
        proposals[proposalIndex].issealed = true;
        valuation = 10;
    }
    
    function Deposit() external payable{
        investors[msg.sender] = true;
        if (proposals[proposalIndex].issealed == false){
            if (proposals[proposalIndex].yes[msg.sender] == true)
            {
                proposals[proposalIndex].voteyes+=msg.value/(valuation/10);
            }
            if (proposals[proposalIndex].no[msg.sender] == true)
            {
                proposals[proposalIndex].voteno+=msg.value/(valuation/10);
            }
        }
        balances[msg.sender] += msg.value/(valuation/10);
        totalBalance += msg.value/(valuation/10);
    }
    
    function withdraw(uint256 amount) external onlyInvestor(){
        require(balances[msg.sender]*(valuation/10) >= amount,"your account dont have enough balances");
        require(proposals[proposalIndex].issealed == true ,"proposal unseal");
        balances[msg.sender] -= amount/(valuation/10);
        totalBalance -= amount/(valuation/10);
        msg.sender.transfer(amount);
    }
    
    
    function createProposal(string memory name) public onlyCurator(){
        require(proposals[proposalIndex].issealed == true);
        proposalIndex++;
        proposals[proposalIndex] = Proposal(name,0,0,false);
    }
    
    function sealproposal() public onlyCurator(){
         Proposal storage _proposal = proposals[proposalIndex];
         require(_proposal.issealed == false);
         require(_proposal.voteyes > totalBalance/2 || _proposal.voteno > totalBalance/2);
         _proposal.issealed = true;
         _changeValuation();
    }
    
    function voteyes() external onlyInvestor(){
        Proposal storage _proposal = proposals[proposalIndex];
        require(votes[msg.sender][proposalIndex] == false);
        require(_proposal.issealed == false);
        votes[msg.sender][proposalIndex] = true;
        _proposal.yes[msg.sender] = true;
        _proposal.no[msg.sender] = false;
        _proposal.voteyes+=balances[msg.sender];
    }
    
    function voteno() external onlyInvestor(){
        Proposal storage _proposal = proposals[proposalIndex];
        require(votes[msg.sender][proposalIndex] == false);
        require(_proposal.issealed == false);
        votes[msg.sender][proposalIndex] = true;
        _proposal.yes[msg.sender] = false;
        _proposal.no[msg.sender] = true;
        _proposal.voteno+=balances[msg.sender];
}
    
    
    
    function _changeValuation() internal{
        
        
    }
    
    
    modifier onlyInvestor(){
        require(investors[msg.sender] == true,"you are not a investor");
        _;
    }
    
    modifier onlyCurator(){
        require(msg.sender == curator);
        _;
    }
} 
