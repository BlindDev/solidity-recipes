// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}



interface ReleasableToken {
    function release() external;
}

interface TransferableToken {
    function transfer(address _to, uint256 _amount) external;
}

interface MintableToken {
    function mint(address _beneficiary, uint256 _numberOfTokens) external;
}


abstract contract SimpleCoin is Ownable, MintableToken, TransferableToken {
   mapping (address => uint256) public coinBalance;
   mapping (address => mapping (address => uint256)) public allowance;
   mapping (address => bool) public frozenAccount;
    
   event Transfer(address indexed from, address indexed to, uint256 value);
   event FrozenAccount(address target, bool frozen);
    
   constructor(uint256 _initialSupply) {
      owner = msg.sender;

      mint(owner, _initialSupply);
   }
    
   function transfer(address _to, uint256 _amount) public override {
     require(_to != address(0x0)); 
     require(coinBalance[msg.sender] > _amount);
     require(coinBalance[_to] + _amount >= coinBalance[_to] );
     coinBalance[msg.sender] -= _amount;  
     coinBalance[_to] += _amount;   
     emit Transfer(msg.sender, _to, _amount);  
   }
    
   function authorize(address _authorizedAccount, uint256 _allowance) 
     public returns (bool success) {
     allowance[msg.sender][_authorizedAccount] = _allowance; 
     return true;
   }
    
   function transferFrom(address _from, address _to, uint256 _amount) 
     public returns (bool success) {
     require(_to != address(0x0)); 
     require(coinBalance[_from] > _amount); 
     require(coinBalance[_to] + _amount >= coinBalance[_to] ); 
     require(_amount <= allowance[_from][msg.sender]);  
     coinBalance[_from] -= _amount; 
     coinBalance[_to] += _amount; 
     allowance[_from][msg.sender] -= _amount;
     emit Transfer(_from, _to, _amount);
     return true;
   }
    
   function mint(address _recipient, uint256  _mintedAmount) 
     onlyOwner public override { 
            
     coinBalance[_recipient] += _mintedAmount; 
     emit Transfer(owner, _recipient, _mintedAmount); 
   }
    
   function freezeAccount(address target, bool freeze) 
     onlyOwner public { 

     frozenAccount[target] = freeze;  
     emit FrozenAccount(target, freeze);
   }
}

contract ReleasableSimpleCoin is SimpleCoin, ReleasableToken { 
    bool public released = false;

    modifier canTransfer() { 
        if(!released) {
            revert();
        }

        _;
    }

    constructor(uint256 _initialSupply) 
        SimpleCoin(_initialSupply) {} 

    function release() onlyOwner public override{ 
        released = true;
    }

    function transfer(address _to, uint256 _amount) 
        canTransfer public override { 
        super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, 
        uint256 _amount) 
        canTransfer public override returns (bool) {
        super.transferFrom(_from, _to, _amount);
    }  
}

interface FundingLimitStrategy {
    function isFullInvestmentWithinLimit(uint256 _investment, uint256 _fullInvestmentReceived) external view returns (bool);
}

contract CappedFundingStrategy is FundingLimitStrategy {
    uint256 fundingCap;

    constructor(uint256 _fundingCap) {
        require(_fundingCap > 0);
        fundingCap = _fundingCap;
    }

    function isFullInvestmentWithinLimit(uint256 _investment, uint256 _fullInvestmentReceived) public override view returns (bool) {
        
        bool check = _fullInvestmentReceived + _investment < fundingCap; 
        return check;
    }
}

contract UnlimitedFundingStrategy is FundingLimitStrategy {
    function isFullInvestmentWithinLimit(uint256 _investment, uint256 _fullInvestmentReceived) public override view returns (bool) {
        return true;
    }
}

abstract contract SimpleCrowdsale is Ownable {
    uint256 public startTime;
    uint256 public endTime; 
    uint256 public weiTokenPrice;
    uint256 public weiInvestmentObjective;

    mapping (address => uint256) public investmentAmountOf;
    uint256 public investmentReceived;
    uint256 public investmentRefunded;

    bool public isFinalized;
    bool public isRefundingAllowed; 

    ReleasableToken public crowdsaleToken; 

    FundingLimitStrategy internal fundingLimitStrategy;

    constructor(uint256 _startTime, uint256 _endTime, 
     uint256 _weiTokenPrice, uint256 _etherInvestmentObjective) 
     payable public
    {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_weiTokenPrice != 0);
        require(_etherInvestmentObjective != 0);

        startTime = _startTime;
        endTime = _endTime;
        weiTokenPrice = _weiTokenPrice;
        weiInvestmentObjective = _etherInvestmentObjective 
            * 1000000000000000000;

        crowdsaleToken = createToken();
        isFinalized = false;
        fundingLimitStrategy = createFundingLimitStrategy();
    } 

    event LogInvestment(address indexed investor, uint256 value);
    event LogTokenAssignment(address indexed investor, uint256 numTokens);
    event Refund(address investor, uint256 value);

    function invest() public payable {
        require(isValidInvestment(msg.value)); 

        address investor = msg.sender;
        uint256 investment = msg.value;

        investmentAmountOf[investor] += investment; 
        investmentReceived += investment; 

        assignTokens(investor, investment);
        emit LogInvestment(investor, investment);
    }

    function createToken() 
        internal returns (ReleasableToken) {
            return new ReleasableSimpleCoin(0);
        }

    function createFundingLimitStrategy() 
        internal returns (FundingLimitStrategy);

    function isValidInvestment(uint256 _investment) 
        internal view returns (bool) {
        bool nonZeroInvestment = _investment != 0;
        bool withinCrowsalePeriod = now >= startTime && now <= endTime; 
             
        return nonZeroInvestment && withinCrowsalePeriod
           && fundingLimitStrategy.isFullInvestmentWithinLimit(
           _investment, investmentReceived);
    }

    function assignTokens(address _beneficiary, 
        uint256 _investment) internal {

        uint256 _numberOfTokens = calculateNumberOfTokens(_investment); 

        crowdsaleToken.mint(_beneficiary, _numberOfTokens);
    }

    function calculateNumberOfTokens(uint256 _investment) 
        internal returns (uint256) {
        return _investment / weiTokenPrice; 
    }

    function finalize() onlyOwner public {
        if (isFinalized) revert();

        bool isCrowdsaleComplete = now > endTime; 
        bool investmentObjectiveMet = investmentReceived 
           >= weiInvestmentObjective;

        if (isCrowdsaleComplete)
        {     
            if (investmentObjectiveMet)
                crowdsaleToken.release();
            else 
                isRefundingAllowed = true;
            isFinalized = true;
        }               
    }

    function refund() public {
        if (!isRefundingAllowed) revert();

        address investor = msg.sender;
        uint256 investment = investmentAmountOf[investor];
        if (investment == 0) revert();
        investmentAmountOf[investor] = 0;
        investmentRefunded += investment;
        emit Refund(msg.sender, investment);

        if (!investor.send(investment)) revert();
    }    
}


contract FixedPricingCrowdsale is SimpleCrowdsale {     

    constructor(uint256 _startTime, uint256 _endTime, 
     uint256 _weiTokenPrice, uint256 _etherInvestmentObjective)
     SimpleCrowdsale(_startTime, _endTime, 
     _weiTokenPrice, _etherInvestmentObjective)

     payable public  {
    }

    function calculateNumberOfTokens(uint256 investment) 
        internal returns (uint256) {
        return investment / weiTokenPrice;
    }    
}

contract TranchePricingCrowdsale is SimpleCrowdsale  {

    struct Tranche {
        uint256 weiHighLimit;
        uint256 weiTokenPrice;
    }

    mapping(uint256 => Tranche) public trancheStructure;
    uint256 public currentTrancheLevel;

    constructor(uint256 _startTime, uint256 _endTime, 
     uint256 _etherInvestmentObjective) 
     SimpleCrowdsale(_startTime, _endTime,
        1, _etherInvestmentObjective)
     payable public
    {
        trancheStructure[0] = Tranche(3000 ether, 0.002 ether);
        trancheStructure[1] = Tranche(10000 ether, 0.003 ether);
        trancheStructure[2] = Tranche(15000 ether, 0.004 ether);
        trancheStructure[3] = Tranche(1000000000 ether, 0.005 ether);

        currentTrancheLevel = 0;
    } 

    function calculateNumberOfTokens(uint256 investment) 
        internal returns (uint256) {
        updateCurrentTrancheAndPrice();
        return investment / weiTokenPrice; 
    }

    function updateCurrentTrancheAndPrice() 
        internal {
        uint256 i = currentTrancheLevel;

        while(trancheStructure[i].weiHighLimit < investmentReceived) 
            ++i;

        currentTrancheLevel = i;

        weiTokenPrice =
           trancheStructure[currentTrancheLevel].weiTokenPrice;
    }
}

contract UnlimitedFixedPricingCrowdsale is FixedPricingCrowdsale {

    constructor(uint256 _startTime, uint256 _endTime, 
     uint256 _weiTokenPrice, uint256 _etherInvestmentObjective)
     FixedPricingCrowdsale(_startTime, _endTime, 
     _weiTokenPrice, _etherInvestmentObjective)
     payable public  {
    }

    function createFundingLimitStrategy() 
        internal returns (FundingLimitStrategy) {
        
        return new UnlimitedFundingStrategy(); 
    }
}

contract CappedFixedPricingCrowdsale is FixedPricingCrowdsale {

    constructor(uint256 _startTime, uint256 _endTime, 
     uint256 _weiTokenPrice, uint256 _etherInvestmentObjective)
     FixedPricingCrowdsale(_startTime, _endTime, 
     _weiTokenPrice, _etherInvestmentObjective)
     payable public  {
    }
    
    function createFundingLimitStrategy() 
        internal returns (FundingLimitStrategy) {
        
        return new CappedFundingStrategy(10000); 
    }
}

contract UnlimitedTranchePricingCrowdsale is TranchePricingCrowdsale {
    
    constructor(uint256 _startTime, uint256 _endTime, 
     uint256 _etherInvestmentObjective)
     TranchePricingCrowdsale(_startTime, _endTime, 
     _etherInvestmentObjective)
     payable public  {
    }
    
    function createFundingLimitStrategy() 
        internal returns (FundingLimitStrategy) {
        
        return new UnlimitedFundingStrategy(); 
    }
}

contract CappedTranchePricingCrowdsale is TranchePricingCrowdsale {
    
    constructor(uint256 _startTime, uint256 _endTime, 
     uint256 _etherInvestmentObjective)
     TranchePricingCrowdsale(_startTime, _endTime, 
     _etherInvestmentObjective)
     payable public  {
    }
    
    function createFundingLimitStrategy() 
        internal returns (FundingLimitStrategy) {
        
        return new CappedFundingStrategy(10000); 
    }
}