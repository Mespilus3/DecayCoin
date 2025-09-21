// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title DecayCoin (DKCN) with 2% transfer decay + burn
/// @notice Fixed supply minted to deployer; each transfer decays 2%
///         (2% is burned, 98% goes to recipient).
contract DecayCoin {
    // --- ERC20 metadata ---
    string public constant name = "DecayCoin";
    string public constant symbol = "DKCN";
    uint8 public constant decimals = 18;

    // --- ERC20 storage ---
    uint256 public totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // --- ERC20 events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // 1.1 billion * 10^18
        uint256 initialSupply = 1_100_000_000 * (10 ** uint256(decimals));
        totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    // --- ERC20 views ---
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    // --- ERC20 core ---
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        if (allowed != type(uint256).max) {
            require(allowed >= amount, "ERC20: insufficient allowance");
            unchecked { _approve(from, msg.sender, allowed - amount); }
        }
        _transfer(from, to, amount);
        return true;
    }

    // --- Burn functions ---
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        uint256 allowed = _allowances[from][msg.sender];
        if (allowed != type(uint256).max) {
            require(allowed >= amount, "ERC20: insufficient allowance");
            unchecked { _approve(from, msg.sender, allowed - amount); }
        }
        _burn(from, amount);
    }

    // --- Internal helpers ---
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from zero");
        require(to != address(0), "ERC20: transfer to zero");

        uint256 fromBal = _balances[from];
        require(fromBal >= amount, "ERC20: transfer exceeds balance");

        // calculate decay (2%)
        uint256 decayAmount = (amount * 2) / 100;
        uint256 sendAmount = amount - decayAmount;

        unchecked {
            _balances[from] = fromBal - amount;
            _balances[to] += sendAmount;
            totalSupply -= decayAmount; // burn the decayed tokens
        }

        emit Transfer(from, to, sendAmount);
        emit Transfer(from, address(0), decayAmount); // show burned portion
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from zero");
        require(spender != address(0), "ERC20: approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "ERC20: burn from zero");
        uint256 bal = _balances[from];
        require(bal >= amount, "ERC20: burn exceeds balance");
        unchecked {
            _balances[from] = bal - amount;
            totalSupply -= amount;
        }
        emit Transfer(from, address(0), amount);
    }
}
