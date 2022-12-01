// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IStarknetCore.sol";

contract Gateway {
    uint256 public endpointGateway;
    IStarknetCore public starknetCore;
    uint256 constant ENDPOINT_GATEWAY_SELECTOR =
        1738423374452994793145864788013146788518531877200292826651981332061687045062;
    uint256 constant BRIDGE_MODE_DEPOSIT = 0;
    uint256 constant BRIDGE_MODE_WITHDRAW = 1;
    uint256 public counter=0;

    // Bootstrap
    constructor(address _starknetCore, uint256 _endpointGateway) {
        require(
            _starknetCore != address(0),
            "Gateway/invalid-starknet-core-address"
        );
        require(
            _endpointGateway != 0,
            "Gateway/invalid-starknet-gateway-address"
        );

        starknetCore = IStarknetCore(_starknetCore);
        endpointGateway = _endpointGateway;
    }


    function changegateway(uint256 gateway)
     external {
        endpointGateway = gateway;
    }

    function changestark(address starknet) external{
        starknetCore = IStarknetCore(starknet);
    }

    // Utils
    function addressToUint(address value)
        internal
        pure
        returns (uint256 convertedValue)
    {
        convertedValue = uint256(uint160(address(value)));
    }

    event BridgeToStarknet(
        address indexed l1ERC721,
        uint256 indexed l2Account,
        uint256 tokenId
    );
    event BridgeFromStarknet(
        address indexed l1ERC721,
        uint256 indexed l2ERC721,
        address indexed l1Account,
        uint256 tokenId
    );

    // Bridging to Starknet
    function bridgeToStarknet(
        IERC721 _l1TokenContract,
        uint256 _tokenId,
        uint256 _account,
        uint256 _floorprice,
        uint256 _requiredtoken

    ) payable external {
        uint256[] memory payload = new uint256[](6);

        // optimistic transfer, should revert if no approved or not owner
        _l1TokenContract.transferFrom(msg.sender, address(this), _tokenId);

        // build deposit message payload
        payload[0] = _account;
        payload[1] = addressToUint(address(_l1TokenContract));
        payload[2] = _tokenId;
        payload[3] = _floorprice;
        payload[4] =  0;
        payload[5] = _requiredtoken;
        

        // send message
        starknetCore.sendMessageToL2{value: msg.value}(
            endpointGateway,
            ENDPOINT_GATEWAY_SELECTOR,
            payload
        );

        emit BridgeToStarknet(
            address(_l1TokenContract),
           
            _account,
            _tokenId
        );
    }

    function bridgeFromStarknetAvailable(
        IERC721 _l1TokenContract,
        uint256 _l2TokenContract,
        uint256 _tokenId
    ) external view returns (bool) {
        uint256[] memory payload = new uint256[](5);

        // build withdraw message payload
        payload[0] = BRIDGE_MODE_WITHDRAW;
        payload[1] = addressToUint(msg.sender);
        payload[2] = addressToUint(address(_l1TokenContract));
        payload[3] = _l2TokenContract;
        payload[4] = _tokenId;

        bytes32 msgHash = keccak256(
            abi.encodePacked(
                endpointGateway,
                addressToUint(address(this)),
                payload.length,
                payload
            )
        );

        return starknetCore.l2ToL1Messages(msgHash) > 0;
    }

    function debug_bridgeFromStarknetAvailable(
        IERC721 _l1TokenContract,
        uint256 _l2TokenContract,
        uint256 _tokenId
    ) external view returns (bytes32) {
        uint256[] memory payload = new uint256[](5);

        // build withdraw message payload
        payload[0] = BRIDGE_MODE_WITHDRAW;
        payload[1] = addressToUint(msg.sender);
        payload[2] = addressToUint(address(_l1TokenContract));
        payload[3] = _l2TokenContract;
        payload[4] = _tokenId;

        bytes32 msgHash = keccak256(
            abi.encodePacked(
                endpointGateway,
                addressToUint(address(this)),
                payload.length,
                payload
            )
        );

        return msgHash;
    }

    // Bridging back from Starknet
    function bridgeFromStarknet(
        IERC721 _l1TokenContract,
        uint256 _l2TokenContract,
        uint256 _tokenId
    ) external {
        uint256[] memory payload = new uint256[](5);

        // build withdraw message payload
        payload[0] = BRIDGE_MODE_WITHDRAW;
        payload[1] = addressToUint(msg.sender);
        payload[2] = addressToUint(address(_l1TokenContract));
        payload[3] = _l2TokenContract;
        payload[4] = _tokenId;

        // consum withdraw message
        starknetCore.consumeMessageFromL2(endpointGateway, payload);

        // optimistic transfer, should revert if gateway is not token owner
        _l1TokenContract.transferFrom(address(this), msg.sender, _tokenId);

        emit BridgeFromStarknet(
            address(_l1TokenContract),
            _l2TokenContract,
            msg.sender,
            _tokenId
        );
    }
}
