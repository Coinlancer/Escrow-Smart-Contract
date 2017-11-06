pragma solidity 0.4.13;
  
 // ----------------------------------------------------------------------------------------------
 // Coinlancer fixed supply token contract
 // Enjoy. (c) etype 2017. The MIT Licence.
 // ----------------------------------------------------------------------------------------------
  
 // ERC Token Standard #20 Interface
 // https://github.com/ethereum/EIPs/issues/20
 contract ERC20Interface {
     // Get the total token supply
     function totalSupply() constant returns (uint256 totalSupply);
  
     // Get the account balance of another account with address _owner
     function balanceOf(address _owner) constant returns (uint256 balance);
  
     // Send _value amount of tokens to address _to
     function transfer(address _to, uint256 _value) returns (bool success);
  
     // Send _value amount of tokens from address _from to address _to
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  
     // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     // this function is required for some DEX functionality
     function approve(address _spender, uint256 _value) returns (bool success);
  
     // Returns the amount which _spender is still allowed to withdraw from _owner
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  
     // Triggered when tokens are transferred.
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
     // Triggered whenever approve(address _spender, uint256 _value) is called.
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
  
 contract Coinlancer is ERC20Interface {
     string public constant symbol = "CL";
     string public constant name = "Coinlancer";
     uint8 public constant decimals = 18;
     uint256 _totalSupply = 300000000000000000000000000;
     
     // Owner of this contract
     address public owner;
  
     // Balances for each account
     mapping(address => uint256) balances;
  
     // Owner of account approves the transfer of an amount to another account
     mapping(address => mapping (address => uint256)) allowed;
  
     // Functions with this modifier can only be executed by the owner
     modifier onlyOwner() {
         require(msg.sender != owner); {
             
          }
          _;
      }
   
      // Constructor
      function Coinlancer() {
          owner = msg.sender;
          balances[owner] = _totalSupply;
      }
  
      function totalSupply() constant returns (uint256 totalSupply) {
         totalSupply = _totalSupply;
      }
  
      // What is the balance of a particular account?
      function balanceOf(address _owner) constant returns (uint256 balance) {
         return balances[_owner];
      }
   
      // Transfer the balance from owner's account to another account
      function transfer(address _to, uint256 _amount) returns (bool success) {
         if (balances[msg.sender] >= _amount 
              && _amount > 0
              && balances[_to] + _amount > balances[_to]) {
              balances[msg.sender] -= _amount;
              balances[_to] += _amount;
              Transfer(msg.sender, _to, _amount);
              return true;
          } else {
              return false;
         }
      }
   
      // Send _value amount of tokens from address _from to address _to
      // The transferFrom method is used for a withdraw workflow, allowing contracts to send
      // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
      // fees in sub-currencies; the command should fail unless the _from account has
      // deliberately authorized the sender of the message via some mechanism; we propose
      // these standardized APIs for approval:
      function transferFrom(
          address _from,
          address _to,
         uint256 _amount
    ) returns (bool success) {
       if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
           && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
           balances[_from] -= _amount;
           allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
             Transfer(_from, _to, _amount);
             return true;
        } else {
            return false;
         }
     }
  
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }
}

contract Escrow
{
    Coinlancer public token;
    
    address public feeAccount;
    address public founder;
    address public owner;
    uint256 public fee;
    
    uint256 fee_mul = 3;

    mapping (uint256 => address[2]) public addresses;
    mapping (uint256 => uint256) public payments;
    
    modifier onlyOwner
    {
        if (msg.sender != owner) throw;
        _;
    }
    
    function Escrow(address token_address)
    {
        token = Coinlancer(token_address);
        founder = msg.sender;
        owner = msg.sender;
    }
    

    function transferOwnership(address newOwner)
    {
        if (msg.sender != founder) throw;
        owner = newOwner;
    }
    
    function setFeeAccount (address new_feeAccount) onlyOwner
    {
        feeAccount = new_feeAccount;
    }
    
    function setFee (uint256 fee) onlyOwner
    {
        fee_mul = fee;
    }
    
    function deposit (uint256 step_id, address from, address to, uint256 amount) onlyOwner
    {
        //uint256 fee;
        addresses[step_id][0] = from;
        addresses[step_id][1] = to;
        payments[step_id] = amount;
        fee = (amount * fee_mul) / 100;
        token.transferFrom(addresses[step_id][0], this, payments[step_id]);    //transfer to escrow
        token.transferFrom(addresses[step_id][0], feeAccount, fee); //withdraw fee
    }
    
    function pay (uint256 step_id) onlyOwner
    {
        token.transfer(addresses[step_id][1], payments[step_id]);
        delete payments[step_id];
        delete addresses[step_id];
    }
    
    function refund (uint256 step_id) onlyOwner
    {
        token.transfer(addresses[step_id][0], payments[step_id]);
        delete payments[step_id];
        delete addresses[step_id];
    }
    
}
