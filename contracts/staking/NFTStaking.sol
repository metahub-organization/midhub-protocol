// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IMid.sol";

contract NFTStaking is Ownable {
    using SafeMath for uint256;
    // using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 points;     // How many points the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.

        //
        // We do some fancy math here. Basically, any point in time, the points of NFT
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.points * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws NFT to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `points` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    mapping(uint256 => uint) public unpaidTokens; //If calculations are good It should never happen
    ITreasury treasury;
    // Info of each pool.
    struct PoolInfo {
        uint256 pointsSupply;     // How many points in this pool.
        uint256 lastRewardBlock;  // Last block number that tokens distribution occurs.
        uint256 accTokenPerShare; // Accumulated tokens per share, times 1e12. See below.
    }

    struct Properties{
        uint256 birthblock;
        bytes3 rarity;
        uint256 seed;
    }

    // The TOKEN!
    IERC20 public token;
    // The Staking NFT.
    IMid public stakingNFT;
    // tokens created per block.
    uint256 public tokenPerBlock;
    // Info of each pool.
    PoolInfo public poolInfo;
    // end block of pool
    uint256 public endBlock;
    // Info of user that stakes LP tokens.
    mapping (uint256 => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 tokenId);
    event Withdraw(address indexed user, uint256 tokenId);
    event WithdrawReward(address indexed user, uint256 tokenId);
    event EmergencyWithdraw(address indexed user, uint256 tokenId);

    constructor( IERC20 _token, IMid _stakingNFT, ITreasury _treasury) {
        token = _token;
        stakingNFT = _stakingNFT;
        treasury = _treasury;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function getPoints(uint256 _tokenId) public view returns (uint16) {
        bytes3 rarity = stakingNFT.getProperty(_tokenId).rarity;
        if (rarity == bytes3('N')) {
            return 5;
        } else if (rarity == bytes3('R')) {
            return 12;
        } else if (rarity == bytes3('SR')) {
            return 30;
        } else if (rarity == bytes3('SSR')) {
            return 75;
        } else if (rarity == bytes3('UR')) {
            return 300;
        } else {
            return 0;
        }
    }

    // View function to see pending tokens on frontend.
    function pendingToken(uint256 _tokenId) external view returns (uint256) {
        assert(stakingNFT.ownerOf(_tokenId) != address(0));
        UserInfo storage user = userInfo[_tokenId];
        uint256 accTokenPerShare = poolInfo.accTokenPerShare;
        uint256 pointsSupply = poolInfo.pointsSupply;
        if (block.number > poolInfo.lastRewardBlock && pointsSupply != 0) {
            uint256 _endBlock = block.number;
            if (block.number > endBlock) {
                _endBlock = endBlock;
            }
            uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, _endBlock);
            uint256 tokenReward = multiplier.mul(tokenPerBlock);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(pointsSupply));
        }
        return user.points.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt).add(unpaidTokens[_tokenId]);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updateReward() public {
        if (block.number <= poolInfo.lastRewardBlock) {
            return;
        }
        uint256 pointsSupply = poolInfo.pointsSupply;
        if (pointsSupply == 0) {
            poolInfo.lastRewardBlock = block.number;
            return;
        }
        uint256 _endBlock = block.number;
        if (block.number > endBlock) {
            _endBlock = endBlock;
        }
        uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, _endBlock);
        uint256 tokenReward = multiplier.mul(tokenPerBlock);
        poolInfo.accTokenPerShare = poolInfo.accTokenPerShare.add(tokenReward.mul(1e12).div(pointsSupply));
        poolInfo.lastRewardBlock = block.number;
    }

    // start a new cycle of staking.
    function updatePool() public {
        if (block.number < endBlock) {
            return;
        }
        if (endBlock > poolInfo.lastRewardBlock) {
            updateReward();
        }
        poolInfo.lastRewardBlock = block.number;
        endBlock = block.number + 100;
        uint256 balance = token.balanceOf(address(treasury));
        uint256 amount = balance.mul(20).div(100);
        treasury.handleOutgoingTransfer(address(this), amount, address(token));
        tokenPerBlock = amount.div(100);
    }

    // Deposit NFT to Staking for Token.
    function deposit(uint256 _tokenId) public {
        assert(msg.sender == stakingNFT.ownerOf(_tokenId));
        UserInfo storage user = userInfo[_tokenId];
        if (user.points > 0) {
            return;
        }
        updateReward();
        user.points = getPoints(_tokenId);
        poolInfo.pointsSupply = poolInfo.pointsSupply.add(getPoints(_tokenId));
        user.rewardDebt = user.points.mul(poolInfo.accTokenPerShare).div(1e12);
        updatePool();
        emit Deposit(msg.sender, _tokenId);
    }

    // Withdraw NFT from Staking.
    function withdraw(uint256 _tokenId) public {
        withdrawReward(_tokenId);
        UserInfo storage user = userInfo[_tokenId];
        poolInfo.pointsSupply = poolInfo.pointsSupply.sub(user.points);
        delete userInfo[_tokenId];
        emit Withdraw(msg.sender, _tokenId);
    }

    // Withdraw reward of NFT.
    function withdrawReward(uint256 _tokenId) public {
        assert(msg.sender == stakingNFT.ownerOf(_tokenId));
        UserInfo storage user = userInfo[_tokenId];
        require(user.points > 0, "withdraw: not good");
        updateReward();
        uint256 pending = user.points.mul(poolInfo.accTokenPerShare).div(1e12).sub(user.rewardDebt).add(unpaidTokens[_tokenId]);
        safeTokenTransfer(msg.sender, pending, _tokenId);
        updatePool();
        emit WithdrawReward(msg.sender, _tokenId);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _tokenId) public {
        assert(msg.sender == stakingNFT.ownerOf(_tokenId));
        UserInfo storage user = userInfo[_tokenId];
        poolInfo.pointsSupply = poolInfo.pointsSupply.sub(user.points);
        emit EmergencyWithdraw(msg.sender, _tokenId);
        delete userInfo[_tokenId];
        unpaidTokens[_tokenId] = 0;
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeTokenTransfer(address _to, uint256 _amount, uint256 _tokenId) internal {
        uint256 balance = token.balanceOf(address(this));
        if (_amount > balance) {
            token.transfer(_to, balance);
            unpaidTokens[_tokenId] = _amount.sub(balance);
        } else {
            token.transfer(_to, _amount);
            unpaidTokens[_tokenId] = 0;
        }
    }

    uint panikked;
    //withdraws token from this Staking
    function panicKK() onlyOwner external{
        if (block.timestamp > panikked) panikked = block.timestamp + 28800;
        else token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}