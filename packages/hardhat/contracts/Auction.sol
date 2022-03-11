// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract Auction is IERC721Receiver {
    // 定义一个nft的拍卖详情的数据结构
    struct tokenDetails {
        address seller;
        uint128 price;
        uint256 duration;
        uint256 maxBid; // 最高的竞拍价
        address maxBidUser; // 最高的竞拍者
        bool isActive;
        uint256[] bidAmounts;
        address[] users;
    }

    // nft合约地址 => tokenId => tokenDetails
    mapping(address => mapping(uint256 => tokenDetails)) public tokenToAuction;

    // nft合约地址 => tokenId => 用户 => 出价
    mapping(address => mapping(uint256 => mapping(address => uint256))) public bids;
    
    /**
       Seller puts the item on auction
       创建拍卖
    */
    function createTokenAuction(
        address _nft,
        uint256 _tokenId,
        uint128 _price,
        uint256 _duration
    ) external {
        require(msg.sender != address(0), "Invalid Address");
        require(_nft != address(0), "Invalid Account");
        require(_price > 0, "Price should be more than 0");
        require(_duration > 0, "Invalid duration value");
        tokenDetails memory _auction = tokenDetails({
            seller: msg.sender,
            price: uint128(_price),
            duration: _duration,
            maxBid: 0,
            maxBidUser: address(0),
            isActive: true,
            bidAmounts: new uint256[](0),
            users: new address[](0)
        });
        address owner = msg.sender;
        // 每次创建拍卖时，需要将nft的转给Auction合约，所以Auction合约是一个IERC721Receiver
        ERC721(_nft).safeTransferFrom(owner, address(this), _tokenId);
        tokenToAuction[_nft][_tokenId] = _auction;
    }
    /**
       Users bid for a particular nft, the max bid is compared and set if the current bid id highest
    */
    function bid(address _nft, uint256 _tokenId) external payable {
        tokenDetails storage auction = tokenToAuction[_nft][_tokenId];
        require(msg.value >= auction.price, "bid price is less than current price");
        require(auction.isActive, "auction not active");
        require(auction.duration > block.timestamp, "Deadline already passed");
        if (bids[_nft][_tokenId][msg.sender] > 0) {
            // 先将用户之前拍卖的钱退还回去
            (bool success, ) = msg.sender.call{value: bids[_nft][_tokenId][msg.sender]}("");
            require(success);
        }
        bids[_nft][_tokenId][msg.sender] = msg.value;
        if (auction.bidAmounts.length == 0) {
            auction.maxBid = msg.value;
            auction.maxBidUser = msg.sender;
        } else {
            uint256 lastIndex = auction.bidAmounts.length - 1;
            // 为什么不拿maxBid比较？;
            require(auction.bidAmounts[lastIndex] < msg.value, "Current max bid is higher than your bid");
            auction.maxBid = msg.value;
            auction.maxBidUser = msg.sender;
        }
        auction.users.push(msg.sender);
        auction.bidAmounts.push(msg.value);
    }
    /**
       Called by the seller when the auction duration is over the hightest bid user get's the nft and other bidders get eth back
       竞拍结束，转移nft的所有权
    */
    function executeSale(address _nft, uint256 _tokenId) external {
        tokenDetails storage auction = tokenToAuction[_nft][_tokenId];
        require(auction.duration <= block.timestamp, "Deadline did not pass yet");
        require(auction.seller == msg.sender, "Not seller");
        require(auction.isActive, "auction not active");
        auction.isActive = false;
        if (auction.bidAmounts.length == 0) {
            ERC721(_nft).safeTransferFrom(
                address(this),
                auction.seller,
                _tokenId
            );
        } else {
            (bool success, ) = auction.seller.call{value: auction.maxBid}("");
            require(success);
            for (uint256 i = 0; i < auction.users.length; i++) {
                if (auction.users[i] != auction.maxBidUser) {
                    // 将所有参与拍卖的用户的钱退还回去
                    (success, ) = auction.users[i].call{
                        value: bids[_nft][_tokenId][auction.users[i]]
                    }("");
                    require(success);
                }
            }
            ERC721(_nft).safeTransferFrom(
                address(this),
                auction.maxBidUser,
                _tokenId
            );
        }
    }

    /**
       Called by the seller if they want to cancel the auction for their nft so the bidders get back the locked eth and the seller get's back the nft
    */
    function cancelAuction(address _nft, uint256 _tokenId) external {
        tokenDetails storage auction = tokenToAuction[_nft][_tokenId];
        require(auction.seller == msg.sender, "Not seller");
        require(auction.isActive, "auction not active");
        auction.isActive = false;
        bool success;
        for (uint256 i = 0; i < auction.users.length; i++) {
        (success, ) = auction.users[i].call{value: bids[_nft][_tokenId][auction.users[i]]}("");        
        require(success);
        }
        ERC721(_nft).safeTransferFrom(address(this), auction.seller, _tokenId);
    }

    function getTokenAuctionDetails(address _nft, uint256 _tokenId) public view returns (tokenDetails memory) {
        tokenDetails memory auction = tokenToAuction[_nft][_tokenId];
        return auction;
    }

    // 这是ERC-721的规定
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    receive() external payable {}
}
