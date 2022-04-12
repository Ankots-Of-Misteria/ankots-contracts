// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ANKTPresale is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    uint256 public constant REFERRAL_ANKT_TOKENS = 18 * (10 ** 18);
    uint256 public constant PURCHASE_ANKT_TOKENS = 83 * (10 ** 18);
    uint256 public constant MAX_ANKT_AP_CONVERSION_PER_PERSON = 3000 * (10 ** 18);
    uint256 public constant MAX_ANKT_CAP = 5990000 * (10 ** 18);
    uint256 public constant depositAmount = 5 * (10 ** 6);
    uint256 public total_ankt_purchased;
    IERC20Upgradeable public usdtAddress;
    address public safeAddress;
    
    mapping(address => ReferralDetails) private userReferralInfo;
    mapping(address => transaction) transactions;

    struct ReferralSummary {
        uint256 timestamp;
        string userName;
        address walletAddress;
        uint256 tokensEarned;
    }

    struct ReferralDetails {
        string userName;
        address walletAddress;
        uint256 totalReferralCount;
        uint256 tokensPurchased;
        uint256 tokensEarned;
        bool apconverted;
        ReferralSummary[] referralHistory;
    }
    
    struct transaction {
        address userAddress;
        uint256 tokenDeposited;
        uint256 createdTime;
        bool doesExist;
    }

    event ReferralCreatedEvent(
        string _inviteeUserName,
        address indexed _inviteeWalletAddress,
        uint256 _inviteeTokensPurchased,
        string _inviterUserName,
        address indexed _inviterWalletAddress,
        uint256 _inviterTokensEarned
    );

    event APconvertedEvent(
        address indexed _walletAddress,
        uint256 _tokensEarned
    );

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function initialize(address safedepositAddress_, address usdtAddress_) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        require(safedepositAddress_ != address(0), "ANKTPresale: deposit address can not be 0 address");
        require(usdtAddress_ != address(0), "ANKTPresale: USDT address can not be 0 address");
        safeAddress = safedepositAddress_;
        usdtAddress = IERC20Upgradeable(usdtAddress_);
    }

    function tokenDeposit(
        string memory _userName,
        string memory _inviterUserName,
        address _inviterWalletAddress
    ) public whenNotPaused nonReentrant returns (bool) {
        require(
            usdtAddress.balanceOf(msg.sender) >= depositAmount,
            "ANKTPresale: You dont have sufficient amount to purchase ankt"
        );
        require(
            usdtAddress.allowance(msg.sender, address(this)) >= depositAmount,
            "ANKTPresale: You have not approved PreSaleDeposit to spend your token"
        );
        require(
            !transactions[msg.sender].doesExist,
            "ANKTPresale: User has already deposited USDT to obtain ANKT"
        );
        require(
            (total_ankt_purchased) <= MAX_ANKT_CAP,
            "ANKTPresale: ANKT Limit exceeded for Deposit"
        );
        transactions[msg.sender].userAddress = msg.sender;
        transactions[msg.sender].tokenDeposited += depositAmount;
        transactions[msg.sender].createdTime = block.timestamp;
        transactions[msg.sender].doesExist = true;
        bool referralUpdateResult = updateUserReferral(_userName, _inviterUserName, _inviterWalletAddress);
        require(referralUpdateResult, "ANKTPresale: referralUpdateResult is failed");
        usdtAddress.transferFrom(msg.sender, address(this), depositAmount);
        return (transactions[msg.sender].doesExist);
    }

    function withdraw() external onlyOwner {
        usdtAddress.transfer(safeAddress, usdtAddress.balanceOf(address(this)));
    }

    function getTransactions(address userAddress) external view returns (bool) {
        return (transactions[userAddress].doesExist);
    }

    function contractBalance() external view returns (uint256) {
        return (usdtAddress.balanceOf(address(this)));
    }

    function updateUserReferral(
        string memory _userName,
        string memory _inviterUserName,
        address _inviterWalletAddress
    ) internal returns (bool) {
        require(msg.sender != _inviterWalletAddress, "ANKTPresale: inviter wallet address and sender address is same");
        userReferralInfo[msg.sender].userName = _userName;
        userReferralInfo[msg.sender].walletAddress = msg.sender;
        userReferralInfo[msg.sender].tokensPurchased = PURCHASE_ANKT_TOKENS;
        total_ankt_purchased = SafeMathUpgradeable.add(total_ankt_purchased, PURCHASE_ANKT_TOKENS);
        if (_inviterWalletAddress != address(0)) {
            userReferralInfo[_inviterWalletAddress].userName = _inviterUserName;
            userReferralInfo[_inviterWalletAddress].walletAddress = _inviterWalletAddress;
            userReferralInfo[_inviterWalletAddress].totalReferralCount += 1;
            userReferralInfo[_inviterWalletAddress].tokensEarned += REFERRAL_ANKT_TOKENS;
            total_ankt_purchased = SafeMathUpgradeable.add(total_ankt_purchased,REFERRAL_ANKT_TOKENS);
            userReferralInfo[_inviterWalletAddress].referralHistory.push(
                ReferralSummary(
                    block.timestamp,
                    _userName,
                    msg.sender,
                    REFERRAL_ANKT_TOKENS
                )
            );
        }
        emit ReferralCreatedEvent(_userName, msg.sender, PURCHASE_ANKT_TOKENS, _inviterUserName, _inviterWalletAddress, REFERRAL_ANKT_TOKENS);
        return true;
    }

    function convertAPtoANKT(address[] memory listofAddresses, uint256[] memory APPoints) external onlyOwner returns (bool)  {
        require(listofAddresses.length > 0, "ANKTPresale: listofAddresses size must be > 0");
        require(APPoints.length > 0, "ANKTPresale: APPoints size must be > 0");
        require(listofAddresses.length == APPoints.length, "ANKTPresale: length of listofAddresses and APPoints should be equal");
        require(listofAddresses.length < 150, "ANKTPresale: listofAddresses size must be < 150");
        for(uint i=0; i< listofAddresses.length; i++){
            for(uint j=0; j<APPoints.length; j++){
                if(i==j){
                    require(listofAddresses[i] != address(0), "ANKTPresale: wallet address should not be 0 address");
                    require(!userReferralInfo[listofAddresses[i]].apconverted, "ANKTPresale: AP already has been converted");
                    require(APPoints[j] <= MAX_ANKT_AP_CONVERSION_PER_PERSON, "ANKTPresale: Max AP Exceeded");
                    uint256 ankt_tokens = SafeMathUpgradeable.div(APPoints[j], 4);
                    userReferralInfo[listofAddresses[i]].tokensEarned += ankt_tokens;
                    userReferralInfo[listofAddresses[i]].walletAddress = listofAddresses[i];
                    userReferralInfo[listofAddresses[i]].apconverted = true;
                    userReferralInfo[listofAddresses[i]].referralHistory.push(
                            ReferralSummary(
                                block.timestamp,
                                "APtoANKT",
                                listofAddresses[i],
                                ankt_tokens
                            )
                    );
                    total_ankt_purchased = SafeMathUpgradeable.add(total_ankt_purchased,ankt_tokens);
                    emit APconvertedEvent(listofAddresses[i], ankt_tokens);
                    break;
                }
            }
        }
        return true;
    }

    function getUserReferralSummary()
        external
        view
        returns (ReferralSummary[] memory summary) {
            return userReferralInfo[msg.sender].referralHistory;
    }

    function getUserANKTBalance() 
        external
        view 
        returns (uint256) {
            return userReferralInfo[msg.sender].tokensPurchased + userReferralInfo[msg.sender].tokensEarned;
    }

    function getUserReferralDetails()
        external
        view
        returns (ReferralDetails memory refDetails) {
            return userReferralInfo[msg.sender];
    }
}