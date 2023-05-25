pragma solidity ^0.8.4;

import "./token/ERC1155/ERC1155Token.sol";
import "./token/ERC721/ERC721Token.sol";
import "./Adminable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BlindBoxFactory is Adminable{

    struct BlindBoxEventInfo {
        uint256 id;
        uint256 startAt;
        uint256 endAt;
        uint256 blindTokenId;
        address blindNft;
        address[] nfts; //（A , B , C）
        uint256[] tokenids; // 0为721, 大于0为1155 (1, 2, 3)
        uint256[] probabilitys; // 前闭后开  （10 ，20 ，30）
        uint256[] minLimit;
        uint256[] maxLimit;
    }

    uint256 public blindBoxEventIndex;
    uint256 public baseDenominator = 10000;
    uint256 private nonce = 1;

    mapping(uint256 => BlindBoxEventInfo) public blindBoxEventInfo;


    event BaseDenominatorChanged(uint256 from, uint256 to);

    event Opened (
        address account,
        uint256 blindBoxEventId,
        uint256 amount
    );

    event OpenedSingle(
        address indexed account,
        address indexed mint,
        uint256 tokenid,
        uint256 amount,
        uint256 blindBoxEventId
    );

    event CreateBlindBoxEvent(
        uint256 id, 
        uint256 startAt, 
        uint256 endAt, 
        uint256 blindTokenId, 
        address blindNft, 
        address[] nfts, 
        uint256[] tokenids, 
        uint256[] probabilitys, 
        uint256[] minLimit, 
        uint256[] maxLimit 
    );

    event ModifyBlindBoxEvent(
        uint256 id, 
        uint256 startAt, 
        uint256 endAt, 
        uint256 blindTokenId, 
        address blindNft, 
        address[] nfts, 
        uint256[] tokenids, 
        uint256[] probabilitys, 
        uint256[] minLimit, 
        uint256[] maxLimit 
    );

    function setBaseDenominator(uint256 _baseDenominator) public onlyOwner {
        emit BaseDenominatorChanged(baseDenominator, _baseDenominator);
        baseDenominator = _baseDenominator;
    }

    function createBlindBoxEvent(address _blindNft, uint256 _startAt, uint256 _endAt, uint256 _blindTokenId,
        address[] memory _nfts, uint256[] memory _tokenids, uint256[] memory _probabilitys,
        uint256[] memory _minLimit, uint256[] memory _maxLimit) public onlyAdmin {
            
        require(_startAt < _endAt, "Start must less than end");
        require(_nfts.length == _tokenids.length && _tokenids.length == _probabilitys.length, "length error");
        uint256 total;
        for(uint256 i = 0; i < _probabilitys.length; ++i) {
            total += _probabilitys[i];
        }
        require(total == baseDenominator, "Probabilitys error");
        blindBoxEventIndex++;
        blindBoxEventInfo[blindBoxEventIndex] = BlindBoxEventInfo(
            blindBoxEventIndex,
            _startAt,
            _endAt,
            _blindTokenId,
            _blindNft,
            _nfts,
            _tokenids,
            _probabilitys,
            _minLimit,
            _maxLimit
        );

        emit CreateBlindBoxEvent(
            blindBoxEventIndex,
            _startAt,
            _endAt,
            _blindTokenId,
            _blindNft,
            _nfts,
            _tokenids,
            _probabilitys,
            _minLimit,
            _maxLimit
        );
    }

    function modifyBlindBoxEvent(uint256 _id, uint256 _startAt, uint256 _endAt, uint256 _blindTokenId, address _blindNft, 
        address[] memory _nfts, uint256[] memory _tokenids, uint256[] memory _probabilitys,
        uint256[] memory _minLimit, uint256[] memory _maxLimit) public onlyAdmin {

        require(_startAt < _endAt, "Start must less than end");
        require(_nfts.length == _tokenids.length && _tokenids.length == _probabilitys.length, "length error");
        uint256 total;
        for(uint256 i = 0; i < _probabilitys.length; ++i) {
            total += _probabilitys[i];
        }
        require(total == baseDenominator, "Probabilitys error");
        BlindBoxEventInfo memory info = blindBoxEventInfo[_id];
        info.startAt = _startAt;
        info.endAt = _endAt;
        info.blindNft = _blindNft;
        info.nfts = _nfts;
        info.tokenids = _tokenids;
        info.probabilitys = _probabilitys;
        info.blindTokenId = _blindTokenId;
        info.minLimit = _minLimit;
        info.maxLimit = _maxLimit;
        blindBoxEventInfo[_id] = info;

        emit ModifyBlindBoxEvent(
            _id, 
            _startAt, 
            _endAt, 
            _blindTokenId, 
            _blindNft, 
            _nfts, 
            _tokenids, 
            _probabilitys,
            _minLimit,
            _maxLimit
        );
    }

    function random() internal returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty,  
            msg.sender, nonce++))) % baseDenominator;
    }

    function openBox(uint256 blindBoxId, uint256 quantity) public {

        BlindBoxEventInfo memory info = blindBoxEventInfo[blindBoxId];

        GameItemERC1155(info.blindNft).burn(msg.sender, info.blindTokenId, quantity);

        for(uint256 n = 0; n < quantity; ++n) {
            uint256 randomid = random();
            uint256 index;
            uint256 front = 0;
            for(uint256 i = 0; i < info.nfts.length; ++i) {
                if(front <= randomid && randomid < front + info.probabilitys[i]) {
                    index = i;
                }
                front = front + info.probabilitys[i];
            }
            uint256 tid = info.tokenids[index];

            uint256 randomAmount = randomid % info.maxLimit[index] + 1;
            if(randomAmount < info.minLimit[index]) {
                randomAmount += info.minLimit[index];
            }

            if(tid == 0) {
                // erc721
                for(uint256 i = 0; i < randomAmount; ++i) {
                    GameItemERC721(info.nfts[index]).mintWithWhiteList(msg.sender);
                }
            } else if (tid == 100000000){
                // eth
                (bool success,) = payable(msg.sender).call{value: randomAmount}("");
                require(success, "Failed to send Ether");
            } else if (tid == 100000001) {
                // erc20
                IERC20(info.nfts[index]).transfer(msg.sender, randomAmount);
            } else {
                // erc1155
                uint256[] memory ids = new uint256[](1);
                uint256[] memory amounts = new uint256[](1);
                ids[0] = tid; 
                amounts[0] = 1;
                GameItemERC1155(info.nfts[index]).mintTokenIdWithWitelist(msg.sender, ids, amounts);
            }
            emit OpenedSingle(msg.sender, info.nfts[index], tid, randomAmount, blindBoxId);
        }
        emit Opened(msg.sender, blindBoxId, quantity);
    }

    receive() external payable {}

}
