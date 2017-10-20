pragma solidity ^0.4.2;
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
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

   event Transfer(address indexed from, address indexed to, uint256 value);

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

    function transfer(address _to, uint256 _value)
    {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    function approve(address _spender, uint256 _value) returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
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
    
   function StandardToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}
   
    function transfer(address _to, uint256 _value)
    {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
    
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
    StandardToken public token; //using interface of ERC20 token
    
    address public feeAccount;
    address public escrow;
	
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
    
    function setComission(uint256 id, uint256 fee) onlyOwner
    {
        comissions[id] = fee;
    }
    
    function stepTransferToEscrow(uint256 id) onlyOwner
    {
        token.transferFrom(addresses[id][0], this, step_payments[id]);    //transfer to escrow
        token.transferFrom(addresses[id][0], feeAccount, comissions[id]); //withdraw fee
    }
    
    function stepTransferToExecutor(uint256 id) onlyOwner
    {
        token.transfer(addresses[id][1], step_payments[id]);
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
