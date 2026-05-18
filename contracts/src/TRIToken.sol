// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Trinity Compute Token ($TRI)
// Minimal self-contained ERC-20 implementation (no external dependencies).
// Mint and burn are exclusively controlled by the TRIBridge contract.
// This design ensures that all token issuance is backed by verifiable
// hardware proof-of-compute receipts from Trinity Triad chips.

contract TRIToken {
    // ─── ERC-20 metadata ────────────────────────────────────────────────────
    string public constant name     = "Trinity Compute Token";
    string public constant symbol   = "TRI";
    uint8  public constant decimals = 18;

    // ─── State ───────────────────────────────────────────────────────────────
    /// @notice Bridge contract address; only bridge may mint or burn.
    address public immutable bridge;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ─── Events ──────────────────────────────────────────────────────────────
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Emitted when new TRI is minted by the bridge after a verified claim.
    event Mint(address indexed to, uint256 amount);

    /// @notice Emitted when TRI is burned by the bridge (e.g., withdrawal back to chip).
    event Burn(address indexed from, uint256 amount);

    // ─── Modifiers ───────────────────────────────────────────────────────────
    modifier onlyBridge() {
        require(msg.sender == bridge, "TRIToken: caller is not bridge");
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────
    /// @param _bridge Address of the TRIBridge contract (immutable after deploy).
    constructor(address _bridge) {
        require(_bridge != address(0), "TRIToken: bridge is zero address");
        bridge = _bridge;
    }

    // ─── ERC-20 view functions ───────────────────────────────────────────────
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    // ─── ERC-20 mutating functions ───────────────────────────────────────────
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        require(allowed >= amount, "TRIToken: insufficient allowance");
        unchecked { _allowances[from][msg.sender] = allowed - amount; }
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // ─── Bridge-controlled mint / burn ───────────────────────────────────────
    /// @notice Mint `amount` TRI to `to`. Called by bridge after receipt validation.
    /// @param to     Recipient wallet address.
    /// @param amount Amount in wei (18 decimals).
    function mint(address to, uint256 amount) external onlyBridge {
        require(to != address(0), "TRIToken: mint to zero address");
        _totalSupply += amount;
        unchecked { _balances[to] += amount; }
        emit Transfer(address(0), to, amount);
        emit Mint(to, amount);
    }

    /// @notice Burn `amount` TRI from `from`. Called by bridge on withdrawal.
    /// @param from   Address whose tokens are burned.
    /// @param amount Amount in wei (18 decimals).
    function burn(address from, uint256 amount) external onlyBridge {
        require(_balances[from] >= amount, "TRIToken: burn exceeds balance");
        unchecked {
            _balances[from] -= amount;
            _totalSupply    -= amount;
        }
        emit Transfer(from, address(0), amount);
        emit Burn(from, amount);
    }

    // ─── Internal helpers ────────────────────────────────────────────────────
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "TRIToken: transfer from zero");
        require(to   != address(0), "TRIToken: transfer to zero");
        require(_balances[from] >= amount, "TRIToken: insufficient balance");
        unchecked {
            _balances[from] -= amount;
            _balances[to]   += amount;
        }
        emit Transfer(from, to, amount);
    }
}
