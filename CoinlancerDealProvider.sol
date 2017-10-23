pragma solidity ^0.4.11;
contract owned
{
    address public owner;

    function owned()
    {
        owner = msg.sender;
    }

    modifier onlyOwner
    {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner
    {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token
{
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function token
    (
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    )
    {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    /* Send coins */
    function transfer(address _to, uint256 _value)
    {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function ()
    {
    //    throw;     // Prevents accidental sending of ether
    }
}

contract StandardToken is owned, token
{
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function StandardToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}
   
    /* Send coins */
    function transfer(address _to, uint256 _value)
    {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
    
    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
}

contract DealProvider
{
    StandardToken public token;
    
    address public feeAccount;
    //= 0xdd870fa1b7c4700f2bd7f44238821c26f7392148;
    address public escrow;
    //= 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;

    
    /* 
    address public client = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;
    address public executor = 0x583031d1113ad414f02576bd6afabfb302140225;
    */
    
    //mapping (uint256 => uint256) public payed_amounts;
    mapping (uint256 => address[2]) public addresses;
    mapping (uint256 => uint256) public comissions;
    mapping (uint256 => uint256) public step_payments;
    
    address public owner;

    
    modifier onlyOwner
    {
        if (msg.sender != owner) throw;
        _;
    }
    
    function DealProvider(address token_address)
    {
        token = StandardToken(token_address);
        owner = msg.sender;
    }
    

    function transferOwnership(address newOwner) onlyOwner
    {
        owner = newOwner;
    }
     
    function setEscrowAccount() onlyOwner
    {
        escrow = this;
    }
   
    function getEscrow() returns (address)
    {
        return escrow;
    }
    
    function setFeeAccount(address new_feeAccount) onlyOwner
    {
        feeAccount = new_feeAccount;
    }
    
    function setAddresses(uint256 id, address client, address executor) onlyOwner
    {
        addresses[id][0] = client;
        addresses[id][1] = executor;
    }
    
    function setStepPayments(uint256 id, uint256 amount) onlyOwner
    {
        step_payments[id] = amount;
    }
    
   /* function setPayedAmount(uint256 id, uint256 amount, uint256 fee) onlyOwner
    {
        payed_amounts[id] = amount;
        comissions[id] = fee;
    }*/
    
    function setComission(uint256 id, uint256 fee) onlyOwner
    {
        comissions[id] = fee;
    }
    
    /*function withdrawFee(uint256 id) onlyOwner
    {
        token.transferFrom(this, feeAccount, comissions[id]);
    }*/
    
    function stepTransferToEscrow(uint256 id) onlyOwner
    {
        token.transferFrom(addresses[id][0], this, step_payments[id]);    //transfer to escrow
        token.transferFrom(addresses[id][0], feeAccount, comissions[id]); //withdraw fee
    }
    
    function stepTransferToExecutor(uint256[] ids) onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++)
        {
            token.transfer(addresses[ids[i]][1], step_payments[ids[i]]);
        }
    }
    
    function refund(uint256 id) onlyOwner
    {
        token.transfer(addresses[id][0], step_payments[id]);
    }
    
    function deleteDeal(uint256 id) onlyOwner
    {
        delete comissions[id];
        delete step_payments[id];
        delete addresses[id];
    }
}
