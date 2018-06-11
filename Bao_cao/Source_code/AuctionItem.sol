pragma solidity ^0.4.24;

import "./DateTime.sol";
contract AuctionItem
{
    address public owner; // nguoi dem vat pham di dau gia
    uint public auctionEnd; // thoi gian ket thuc
    DateTime dt;

    // Trang thai hien tai cua qua trinh dau gia
    address public highestBidder; // nguoi dau gia cao nhat
    uint public highestBid; // gia dau cao nhat
    uint public defaultBid; // gia dau khoi diem

    // Cho phep nguoi dau gia thap hon rut tien lai
    mapping(address => uint) pendingReturns;
    // Ma vat pham
    mapping(address => string) itemKey;

    // Cho phep nguoi dem vat pham di dau gia huy ban dau gia.
    // Neu cuoc ban dau gia khong bi huy thi se duoc gan gia tri true khi
    // ket thuc phien dau gia nham khong cho phep su can thiep sau thoi han.
    bool ended = false;

    // Cac su kien trong phien dau gia
    /// Gia dau tang!
    event HighestBidIncreased(address bidder, uint amount);
    /// Ket thuc!
    event AuctionEnded(address winner, uint amount);

    /// Tao mot hop dong dau gia thong minh voi thoi gian dau gia la
    /// '_biddingTime' giay, muc gia khoi diem la '_defaultBid' Ether
    /// , vat pham co ma dinh danh '_itemKey'
    /// nguoi dem vat pham di dau gia co dia chi '_owner'.
    /// Thoi gian dau gia co the duoc dieu chinh lai.
    constructor(
        uint _biddingTime,
        address _owner,
        uint _defaultBid,
        string _itemKey,
        address addrDatetime
    ) public {
        owner = _owner;
        auctionEnd = now + _biddingTime;
        highestBid = _defaultBid;
        defaultBid = _defaultBid;
        itemKey[owner] = _itemKey;
        dt = DateTime(addrDatetime);
    }

    /// Thay doi tinh trang hop dong boi nguoi dem vat pham di dau gia
    modifier onlyBy(address account) {
        require(
            msg.sender == account,
            "Khong co quyen thuc hien."
        );
        _;
    }
    
    /// Huy phien dau gia hien tai!
    function cancel() public onlyBy(owner){
        ended = true;
        // Tra tien lai cho nguoi dau gia
        if (highestBid != defaultBid) {
            // De nguoi choi tu rut tien
            pendingReturns[highestBidder] += highestBid;
            delete highestBidder;
            highestBid = defaultBid;
        }
    }
    
    /// Kich hoat lai phien dau gia!
    function activeAgain() public onlyBy(owner) {
        // Chi duoc kich hoat lai khi con thoi gian dau gia.
        require(now <= auctionEnd, "Khong the kich hoat lai.");
        ended = false;
    }
    
    /// Dat thoi gian ket thuc dau gia neu muon thoi gian dau gia keo dai hon.
    function alterAuctionEndTime (
        uint16 year, 
        uint8 month, 
        uint8 day, 
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public
      onlyBy(owner) {
      	require(
	    !ended, "Phien da ket thuc! Khong the thay doi!"
	);
        uint timeStamp = 
            dt.toTimestamp(year, month, day, hour, minute, second);
	require(
	    timeStamp > auctionEnd
	    , "Thoi han moi khong lon hon thoi han ban dau!"
	);
	auctionEnd = timeStamp;
    }

    /// Dau gia voi so tien di kem giao dich nay.
    /// Tien chi duoc hoan lai neu ban khong thang.
    function bid() public payable {
        
        // Huy giao dich neu qua han.
        require(
            now <= auctionEnd,
            "Phien dau gia ket thuc!"
        );
        
        // Phien dau gia phai dang trong qua trình hoat dong
        require(
            !ended,
            "Vat pham da bi huy ban dau gia!"
        );

        // Khong chap nhan muc gia thap hon muc gia dau hien tai.
        require(
            msg.value > highestBid,
            "Da co gia dau cao hon!!"
        );
        
        // Nguoi choi phai dam bao co du tien.
        require(
            msg.value <= msg.sender.balance,
            "Ban khong du tien de tham gia!"
        );

        if (highestBid != defaultBid) {
            // Nguoi choi co gia dau thap hon co the tu rut tien lai
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// Rut tien trong truong hop co nguoi khac tra cao hon.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // Dat lai ve 0 de tranh truong hop gian lan rut nhieu lan.
            pendingReturns[msg.sender] = 0;
            
            // Neu rut tien khong thanh cong
            if (!msg.sender.send(amount)) {
                // Xem nhu chua rut.
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// Ket thuc phien dau gia, gui tien cho nguoi đem vat phẩm đi đấu giá,
    /// gui ma vat pham cho nguoi thang cuoc.
    function auctionEnd() public {
        // 1. Conditions
        require(now >= auctionEnd, "Phien dau gia chua ket thuc.");
        require(!ended, "Phien dau gia khong hoat dong.");

        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interaction
        // Neu co nguoi dau gia
	if (highestBid != defaultBid) {
	    owner.transfer(highestBid);
	    itemKey[highestBidder] = itemKey[owner];
	    itemKey[owner] = "";
	}
	// else do nothing
	// Thuc te thi he thong se tra lai vat pham cho nguoi dem no di dau gia.
    }
}
