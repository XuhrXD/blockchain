pragma solidity ^0.5.0;

contract DAOInterface {
    
    struct Proposal {
        string description;
        uint voteyes;
        uint voteno;
        bool issealed;
        mapping(address => bool)  yes;
        mapping(address => bool)  no;
    }
    
    uint256 public totalBalance;
    uint256 public proposalIndex;
    uint256 public valuation;
    address public curator;
    address[] public addresslist;
    mapping(uint => Proposal) public proposals;
    mapping(address => bool) public investors;
    mapping (address => uint256) public balances;
    mapping(address =>mapping(uint => bool)) public votes;
    
    
    constructor() public {
        totalBalance = 0;
        proposalIndex = 0;
        proposals[proposalIndex].issealed = true;
        valuation = 1;
        curator = msg.sender;
    }
    
     modifier onlyCurator(){
        require(msg.sender == curator,"you are not the curator");
        _;
    }
    
    function DelegateCurator(address newCurator) onlyCurator  public {
        require(proposals[proposalIndex].issealed == false);
        curator = newCurator;
    }
}

contract DAO is DAOInterface{
    
    function Deposit() external payable returns (bool success){
        investors[msg.sender] = true;
        if (proposals[proposalIndex].issealed == false){
            if (proposals[proposalIndex].yes[msg.sender] == true)
            {
                proposals[proposalIndex].voteyes+=msg.value/(valuation);
            }
            if (proposals[proposalIndex].no[msg.sender] == true)
            {
                proposals[proposalIndex].voteno+=msg.value/(valuation);
            }
        }
        
        balances[msg.sender] += msg.value/(valuation);
        totalBalance += msg.value/(valuation);
    
        for (uint i=0; i<addresslist.length; i++){
            if (addresslist[i] == msg.sender){
                return true;
            }
        }
        addresslist.push(msg.sender);
        return true;
    }
    
    function withdraw(uint256 amount) external onlyInvestor(){
        require(balances[msg.sender]*(valuation) >= amount,"your account dont have enough balances");
        require(proposals[proposalIndex].issealed == true ,"proposal unseal");
        balances[msg.sender] -= amount/(valuation);
        totalBalance -= amount/(valuation);
        msg.sender.transfer(amount);
        if (balances[msg.sender] == 0){
            investors[msg.sender] = false;
            for (uint256 i=0; i<addresslist.length; i++){
                if (addresslist[i] == msg.sender){
                    delete addresslist[i];
                    break;
                }
            }
        investors[msg.sender]=false;
        }
    }
    
    function getBalance() public view returns (uint256 currentbalance){
        currentbalance = balances[msg.sender];
    }
    
    function createProposal(string memory name) public onlyCurator(){
        require(proposals[proposalIndex].issealed == true,"current proposal is not sealed");
        proposalIndex++;
        proposals[proposalIndex] = Proposal(name,0,0,false);
    }
    
    function sealproposal() public onlyCurator(){
        //mannually seal the proposal
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
        if (_proposal.voteyes > totalBalance/2){
            _proposal.issealed = true;
            _changeValuation();
        }
    }
    
    function voteno() external onlyInvestor(){
        Proposal storage _proposal = proposals[proposalIndex];
        require(votes[msg.sender][proposalIndex] == false);
        require(_proposal.issealed == false);
        votes[msg.sender][proposalIndex] = true;
        _proposal.yes[msg.sender] = false;
        _proposal.no[msg.sender] = true;
        _proposal.voteno+=balances[msg.sender];
        if (_proposal.voteno > totalBalance/2){
            _proposal.issealed = true;
        }
    }
    
    function _changeValuation() internal{
        uint random_number = uint256(keccak256(abi.encodePacked(block.difficulty, now)))%100;
        valuation = valuation * (random_number/10);
        if (valuation == 0 ) {
            totalBalance = 0;
            for (uint i=0; i<addresslist.length; i++){
                delete balances[addresslist[i]];
            }
            valuation = 10;
        }
        
    }
    
    modifier onlyInvestor(){
        require(investors[msg.sender] == true,"you are not a investor");
        _;
    }
    
   
}  
