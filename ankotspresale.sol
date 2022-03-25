
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ANKTPreSale is Ownable {

    uint256 private constant REFERRAL_ANKT_TOKENS = 18 * (10 ** 18);
    uint256 private constant PURCHASE_ANKT_TOKENS = 83 * (10 ** 18);
    uint256 private total_ankt_purchased = 0;
    uint256 depositAmount = 5 * (10 ** 6);

    address public _usdtAddress;
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

    event ReferralPointsUpdated(
        address _inviteeWalletAddress,
        address _inviterWalletAddress,
        string _inviterUserName
    );
    
    
    constructor(address depositAddress, address token) {
        safeAddress = depositAddress;
        _usdtAddress = token;
    }

    function tokenDeposit(
        string memory _userName,
        string memory _inviterUserName,
        address _inviterWalletAddress
    ) public returns (bool) {
        IERC20 _j = IERC20(_usdtAddress);
        require(
            _j.allowance(msg.sender, address(this)) >= depositAmount,
            "TokenDeposit: you have not approved PreSaleDeposit to spend your token"
        );
        require(
            transactions[msg.sender].doesExist == false,
            "User has already deposited USDT to obtain ANKT"
        );
        require(
            (total_ankt_purchased) <= 5990000 * (10 ** 18),
            "Limit exceeded for Deposit"
        );
        _j.transferFrom(msg.sender, address(this), depositAmount);
        transactions[msg.sender].userAddress = msg.sender;
        transactions[msg.sender].tokenDeposited += depositAmount;
        transactions[msg.sender].createdTime = block.timestamp;
        transactions[msg.sender].doesExist = true;
        updateUserReferral(_userName, _inviterUserName, _inviterWalletAddress);

        return (transactions[msg.sender].doesExist);
    }

    function withdraw() public payable onlyOwner {
        IERC20 _j = IERC20(_usdtAddress);
        _j.transfer(safeAddress, _j.balanceOf(address(this)));
    }

    function getTransactions(address userAddress) public view returns (bool) {
        return (transactions[userAddress].doesExist);
    }

    function contractBalance() public view returns (uint256) {
        ERC20 t = ERC20(_usdtAddress);
        return (t.balanceOf(address(this)));
    }

    function updateUserReferral(
        string memory _userName,
        string memory _inviterUserName,
        address _inviterWalletAddress
    ) internal returns (bool) {
        require(
            msg.sender != _inviterWalletAddress,
            "inviter wallet address and sender address is same!"
        );
        userReferralInfo[msg.sender].userName = _userName;
        userReferralInfo[msg.sender].walletAddress = msg.sender;
        userReferralInfo[msg.sender].tokensPurchased = PURCHASE_ANKT_TOKENS;
        total_ankt_purchased = SafeMath.add(
            total_ankt_purchased,
            PURCHASE_ANKT_TOKENS
        );
        
        if (_inviterWalletAddress != address(0)) {
            userReferralInfo[_inviterWalletAddress].userName = _inviterUserName;
            userReferralInfo[_inviterWalletAddress].walletAddress = _inviterWalletAddress;
            userReferralInfo[_inviterWalletAddress].totalReferralCount += 1;
            userReferralInfo[_inviterWalletAddress].tokensEarned += REFERRAL_ANKT_TOKENS;
            total_ankt_purchased = SafeMath.add(total_ankt_purchased,REFERRAL_ANKT_TOKENS);
            userReferralInfo[_inviterWalletAddress].referralHistory.push(
                ReferralSummary(
                    block.timestamp,
                    _userName,
                    msg.sender,
                    REFERRAL_ANKT_TOKENS
                )
            );
        }
        emit ReferralPointsUpdated(
            msg.sender,
            _inviterWalletAddress,
            _inviterUserName
        );
        return true;
    }

    function convertAPtoANKT(address[] memory listofAddresses, uint256[] memory APPoints) external  onlyOwner returns (bool)  {
        for(uint i=0; i< listofAddresses.length; i++){
            for(uint j=0; j<APPoints.length; j++){
                if(i==j){
                    require(userReferralInfo[listofAddresses[i]].apconverted == false, "AP already has been converted");
                    require(APPoints[j] < 3000000000000000000000, "Max AP Exceeded");
                    uint256 ankt_tokens = SafeMath.div(APPoints[j], 4);
                    userReferralInfo[listofAddresses[i]]
                            .tokensEarned += ankt_tokens;
                    userReferralInfo[listofAddresses[i]]
                            .walletAddress = listofAddresses[i];
                    userReferralInfo[listofAddresses[i]].apconverted = true;
                    userReferralInfo[listofAddresses[i]].referralHistory.push(
                            ReferralSummary(
                                block.timestamp,
                                "APtoANKT",
                                listofAddresses[i],
                                ankt_tokens
                            )
                    );
                    total_ankt_purchased = SafeMath.add(total_ankt_purchased,ankt_tokens);
                }
            }
        }
        return true;
    }



    function getUserReferralSummary()
        external
        view
        returns (ReferralSummary[] memory summary)
    {
        return userReferralInfo[msg.sender].referralHistory;
    }

    function getUserBalance() external view returns (uint256) {
        return
            userReferralInfo[msg.sender].tokensPurchased +
            userReferralInfo[msg.sender].tokensEarned;
    }

    function getUserReferralDetails()
        external
        view
        returns (ReferralDetails memory refDetails)
    {
        return userReferralInfo[msg.sender];
    }

     function getTotalPurchasedTokens()
        external
        view onlyOwner
        returns (uint256)
    {
        return total_ankt_purchased;
    }
}
