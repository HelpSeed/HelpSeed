// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ILAND {
    function mintLandOwner(
        bytes15 hexId,
        address to,
        bytes2 flag
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);
    function transferOwnership(address newOwner) external;
}

contract HelpSeedMiner is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    ILAND private helpsLand;
    uint256 private _landPrice;
    uint256 private referenceReward;

    // Miner Levels Index =  0 = BRONZ , 1 = SILVER ,2 = GOLD , 3 = PLATINUM

    receive() external payable {}

    fallback() external payable {}

    constructor() {

        _landPrice = 16000000000000000;
        referenceReward = 260000 * 10**18;
        uint256[4] memory firstLevelPerc = [uint256(350),uint256(450), uint256(550),uint256(650)];
        helpsLand = ILAND(0xd8A2953646FD5D8f6299f4a7F93d9e58Aa70F054);
        newPool(0x0A6e6D2F58d22E267Fdc9bfB295F0d43985FEBB4, 15, firstLevelPerc);
        _unlockPrice[0] = 32000000000000000; 
        _unlockPrice[1] = 63000000000000000;
        _unlockPrice[2] = 95000000000000000;
        _unlockPrice[3] = 130000000000000000;
    }

    event UnlockMiner(address indexed user);
    event LockMiner(address indexed user);
    event NewPool(address token, uint256 maxParticipate);
    event UpdatePool(uint256 index, address token, uint256 maxParticipate);
    event DeletePool(uint256 index);
    event JoinPool(address user, address token);
    event UpdateLevelEarnPerc(uint256 level, uint256 rate);
    event UpdateLandPrice(uint256 oldA, uint256 newA);
    event UpdateUnlockPrice(uint256 oldA, uint256 newA);
    event ClaimEarn(uint256 time, uint256 earnAmount);

    struct Pool {
        address token;
        uint256 index;
        address[] participants;
        uint256[4] levelPerc;
        uint256 maxParticipants;
        bool isExits;
    }

    struct Miner {
        uint256 totalEarn;
        uint256 nextMiningTime;
        uint256 endTime;
        uint256 poolIndex;
        uint256 poolParticipantIndex;
        bool isJoinedPool;
        bool isStatus;
    }

    Pool[] private pools;
    uint256 private poolIndex;

    mapping(address => Miner) private miners;
    mapping(address => uint256) private poolToken;
    mapping(uint256 => uint256) private _unlockPrice;
    mapping(address => address[]) private refs;
    mapping(address => address) private refUser;
    mapping(address => bool) internal refExits;

    /**
    * @dev  Create Pool
     **/

    function newPool(
        address token,
        uint256 maxParticipants,
        uint256[4] memory _levelPerc
    ) public onlyOwner {
        uint256 index = poolIndex++;
        address[] memory adr;
        pools.push(Pool(token, index, adr, _levelPerc, maxParticipants, true));
        emit NewPool(token, maxParticipants);
    }

    /**
     * @dev Join User
     **/
    function _joinPool(uint256 index) internal {
        Pool memory pool = pools[index];
        Miner memory miner = miners[_msgSender()];
        require(
            miner.isJoinedPool == true
                ? miner.poolIndex != index
                : miner.poolIndex == index,
            "Already joined."
        );
        uint256 newParticipant = pool.participants.length;
        require(
            newParticipant.add(1) <= pool.maxParticipants,
            "Pool Participate Capacity is Full"
        );

        if (miner.isJoinedPool) {
            address[] memory newPoolParticipants = leavePool(miner.poolIndex);
            pools[miner.poolIndex].participants = newPoolParticipants;
        }

        pools[index].participants.push(_msgSender());
        miner.poolIndex = index;
        miner.isJoinedPool = true;
        miner.poolParticipantIndex = pools[index].participants.length;
        miners[_msgSender()] = miner;
        emit JoinPool(_msgSender(), pools[index].token);
    }

    /**
     * @dev Join Pool
     **/

    function joinPool(uint256 index) public nonReentrant {
        require(pools[index].isExits == true, "This Pool Not Found");
        require(
            miners[_msgSender()].isStatus == true,
            "Your Miner Mode is Disabled."
        );
        _joinPool(index);
    }

    /**
     * @dev Leave Pool
     **/

    function leavePool(uint256 index) internal returns (address[] memory) {
        for (uint256 i = index; i < pools[index].participants.length - 1; i++) {
            pools[index].participants[i] = pools[index].participants[i + 1];
        }

        pools[index].participants.pop();
        return pools[index].participants;
    }

    /**
     * @dev List Pool Participants
     **/

    function getPoolParticipants(uint256 index)
        public
        view
        returns (address[] memory)
    {
        return pools[index].participants;
    }

    /**
     * @dev Update Pool
     **/

    function updatePool(
        uint256 index,
        address token,
        uint256 maxParticipants
    ) public onlyOwner {
        require(pools[index].isExits == true, "Already Pool");
        Pool memory pool = pools[index];
        pool.token = token;
        pool.maxParticipants = maxParticipants;
        pools[index] = pool;
        emit UpdatePool(index, token, maxParticipants);
    }

    /**
     * @dev Delete Pool
     **/

    function deletePool(uint256 index) public onlyOwner {
        require(
            pools[index].participants.length <= 0,
            "Miners are present, the pool cannot be deleted before they leave."
        );
        require(pools[index].isExits == true, "Already Pool");

        IERC20(pools[index].token).transfer(
            owner(),
            getBalanceToken(pools[index].token)
        );

        for (uint256 i = index; i < pools.length - 1; i++) {
            pools[i] = pools[i + 1];
        }
        poolIndex--;
        emit DeletePool(index);
        return pools.pop();
    }

    /**
     * @dev Update Pool Perctange Level.
     **/

    function updatePoolLevelPerc(
        uint256 index,
        uint256 _level,
        uint256 rate
    ) public onlyOwner {
        require(pools[index].isExits == true, "This Pool Not Found");
        pools[index].levelPerc[_level] = rate;
        emit UpdateLevelEarnPerc(_level, rate);
    }

    /**
     * @dev Set Land Price.
     **/
    function setLandPrice(uint256 l) public onlyOwner {
        require(l > 0, "Don't Set Zero");
        uint256 oldPrice = _landPrice;
        _landPrice = l;
        emit UpdateLandPrice(oldPrice, _landPrice);
    }


    /**
     * @dev Land Contract Set New Owner
     **/
    function landTransferOwnership(address newOwner) public onlyOwner {
helpsLand.transferOwnership(newOwner);
    }

    /**
     * @dev Set Unlock Miner Price.
     **/
    function setUnlockMinerPrice(uint256 _level, uint256 u) public onlyOwner {
        require(u > 0, "Don't Set Zero");
        uint256 oldPrice = _unlockPrice[_level];
        _unlockPrice[_level] = u;
        emit UpdateUnlockPrice(oldPrice, _unlockPrice[_level]);
    }

    /**
     * @dev Returns Land Price.
     **/
    function landPrice() public view returns (uint256) {
        return _landPrice;
    }

    /**
     * @dev Returns  Unlock Miner Price.
     **/
    function unlockPrice()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _unlockPrice[0], // 0 = BRONZ
            _unlockPrice[1], // 1 = SILVER
            _unlockPrice[2], // 2 = GOLD
            _unlockPrice[3]  // 3 = PLATINUM
        );
    }

    /**
     * @dev - Check and Get Miner Level
     **/
    function minerLevel() internal view returns (uint256) {
        uint256 landCount = helpsLand.balanceOf(_msgSender());
        require(landCount > 0);
        if (landCount <= 100) {
            return 0; // BRONZ
        } else if (landCount > 100 && landCount <= 1000) {
            return 1; // SILVER
        } else if (landCount > 1000 && landCount <= 10000) {
            return 2; // GOLD
        } else {
            return 3; // PLATINUM
        }
    }

    /**
     * @dev Calculate Daily Earn
     **/

    function calculateDailyEarn() internal view returns (uint256) {
        Pool storage pool = pools[miners[_msgSender()].poolIndex];
        uint256 perMinerAmount = getBalanceToken(pools[miners[_msgSender()].poolIndex].token).div(pool.maxParticipants);
        return perMinerAmount.mul(pool.levelPerc[minerLevel()]).div(1000);
    }


    /**
     * @dev User Returns Miner Data
     **/
    function getPool(uint256 index) public view returns (Pool memory) {
        require(pools[index].isExits == true, "Not Found Pool.");
        return pools[index];
    }

    /**
     * @dev Returns List Pagination Pools.
     **/

    function getPools(uint256 offset, uint256 limit)
        public
        view
        returns (
            Pool[] memory,
            uint256 nextOffset,
            uint256 total
        )
    {
        uint256 totalPools = pools.length;
        if (limit == 0) {
            limit = 1;
        }

        if (limit > totalPools - offset) {
            limit = totalPools - offset;
        }

        Pool[] memory values = new Pool[](limit);
        for (uint256 i = 0; i < limit; i++) {
            values[i] = pools[offset + i];
        }

        return (values, offset + limit, totalPools);
    }

    /**
     * @dev Returns Number of Tokens in the Pool
     **/

    function getBalanceToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @dev User Set Lock Miner
     **/
    function _lockMiner(address user) private {
        miners[user].isStatus = false;
    }

    /**
     * @dev User Miner Expiry Detection
     **/
    function expireDetect(uint256 endTime) internal {
        if (endTime <= block.timestamp) {
            _lockMiner(_msgSender());
            emit LockMiner(_msgSender());
        }
    }


    /**
     * @dev User Set Unlock Miner
     **/
    function unlock(address user) private {
        miners[user].isStatus = true;
        miners[user].nextMiningTime = block.timestamp;
        miners[user].endTime = block.timestamp + 30 days;
        if(miners[user].isJoinedPool == false){
            _joinPool(0); // Join Default Pool;
        }
    }

    /**
     * @dev User Returns Miner Struct Data
     **/
    function getMiner(address user) public view returns (Miner memory) {
        require(user != address(0));
        require(helpsLand.balanceOf(user) > 0);
        return miners[user];
    }

    /**
     * @dev Unlock Miner Mode.
     **/

    function unlockMinerMode() public payable nonReentrant {
        require(_msgSender() != address(0));
        require(msg.value >= _unlockPrice[minerLevel()], "balance not enought");
        require(helpsLand.balanceOf(_msgSender()) > 0, "You Don't Have Land.");
        require(miners[_msgSender()].endTime <= block.timestamp, "Until time");
        payable(owner()).transfer(msg.value);
        unlock(_msgSender());
        emit UnlockMiner(_msgSender());
    }

    /**
     * @dev User Claim Action.
     **/

    function claimEarn() public nonReentrant {
        require(_msgSender() != address(0));
        require(helpsLand.balanceOf(_msgSender()) > 0, "You Don't Have Land.");
        Miner memory miner = miners[_msgSender()];
        require(miner.isStatus == true, "Miner Mode Disable");
        expireDetect(miner.endTime);
        require(miner.nextMiningTime < block.timestamp, "Until Time");
        uint256 earnAmount = calculateDailyEarn();
        miner.nextMiningTime = block.timestamp + 1 days;
        miner.totalEarn = miner.totalEarn.add(earnAmount);
        miners[_msgSender()] = miner;
        IERC20(pools[miner.poolIndex].token).transfer(_msgSender(), earnAmount);
        emit ClaimEarn(block.timestamp, earnAmount);
    }

    /**
     * @dev Set Reference Reward Token Amount
     **/

    function setReferenceReward(uint256 v) public onlyOwner {
        require(v > 0, "Don't Set Zero");
        referenceReward = v;
    }

    /**
     * @dev Returns Reference Reward Token Amount
     **/

    function getRefenceReward() internal view returns (uint256) {
        return referenceReward;
    }

    /**
     * @dev Set Reference Address And Send Reward Amount.
     **/

    function _setRef(address from) internal {
        require(_msgSender() != from, "False");
        refs[from].push(_msgSender());
        refExits[_msgSender()] = true;
    }

    /**
     * @dev Returns User Reference Address.
     **/

    function getRefs(address user) public view returns (address[] memory) {
        return refs[user];
    }

    /**
     * @dev Buy Land.
     **/

    function buyLand(
        bytes15 hexId,
        bytes2 _f,
        address ref
    ) public payable nonReentrant {
        require(msg.value >= _landPrice, "balance not enought");
        // the land sale, the coin goes to the Contract owner owner().
        helpsLand.mintLandOwner(hexId, _msgSender(), _f);
        payable(owner()).transfer(msg.value);
        if (refExits[_msgSender()] == false) {
            _setRef(ref);
            IERC20(0x0A6e6D2F58d22E267Fdc9bfB295F0d43985FEBB4).transfer(
                ref,
                getRefenceReward()
            );
        }
    }
}
