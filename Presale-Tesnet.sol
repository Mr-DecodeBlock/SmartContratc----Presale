// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Presale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable paymentToken; // token utilizado para comprar el token de la presale
    address public immutable presaleWallet; // dirección donde se recibirán los pagos

    uint256 public immutable tokenRate; // tasa de conversión del token de la presale en unidades de paymentToken
    uint256 public tokensSold; // cantidad de tokens de la presale vendidos
    mapping(address => uint256) public tokenBalance; // cantidad de tokens disponibles por dirección

    event TokensPurchased(address buyer, uint256 amount, uint256 rate);
    event TokensRecovered(uint256 amount);
    event TokensAdded(uint256 amount);
    event Withdrawn(address indexed buyer, uint256 amount, address tokenAddress);

    constructor(
        IERC20 _paymentToken,
        address _presaleWallet,
        uint256 _tokenRate
    ) {
        require(
            address(_paymentToken) != address(0),
            "Preventa: direccion de token de pago no valida"
        );
        require(
            _presaleWallet != address(0),
            "Preventa: direccion de billetera de preventa no valida"
        );
        require(
            _tokenRate > 0,
            "Preventa: la tasa de conversion del token debe ser mayor que cero"
        );

        //Rate
        // 1000000000000000000  Enviar 1 USDT : Recibir 1 Token
        // 900000000000000000   Enviar 1 USDT : Recibir 0.90 Token

        paymentToken = _paymentToken;
        presaleWallet = _presaleWallet;
        tokenRate = _tokenRate;
    }

    function buyTokens(uint256 paymentAmount, address recipient)
        external
        nonReentrant
    {
        require(
            paymentAmount > 0,
            "Preventa: el monto del pago debe ser mayor que cero"
        );
        uint256 amount = uint256(paymentAmount).mul(tokenRate).div(1e18);
        require(amount > 0, "Preventa: el monto debe ser mayor a cero");
        paymentToken.safeTransferFrom(msg.sender, presaleWallet, paymentAmount);
        tokenBalance[presaleWallet] = tokenBalance[presaleWallet].sub(amount);
        tokenBalance[recipient] = tokenBalance[recipient].add(amount);
        tokensSold = tokensSold.add(amount);
        emit TokensPurchased(msg.sender, amount, tokenRate);

        IERC20 token = IERC20(0xf56440Ea891495cb319d9271B65a5347ed4c3F82);
        token.safeTransfer(recipient, amount);
        emit Withdrawn(msg.sender, amount, 0xf56440Ea891495cb319d9271B65a5347ed4c3F82);
    
    }

    function withdrawUSDTTokensToOwner() public onlyOwner nonReentrant {
        uint256 balance = paymentToken.balanceOf(address(this)); // Obtener la cantidad de tokens disponibles en el contrato
        paymentToken.safeTransfer(owner(), balance); // Transferir todos los tokens al dueño del contrato
        emit TokensRecovered(balance);
    }

    function withdrawTokenToOwner() public onlyOwner {
        IERC20(0xf56440Ea891495cb319d9271B65a5347ed4c3F82).transfer(owner(), IERC20(0xf56440Ea891495cb319d9271B65a5347ed4c3F82).balanceOf(address(this)));
    }

    function withdrawAllETH() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No hay BNB para retirar");
        payable(owner()).transfer(balance);
    }

    function addTokens(uint256 amount) public onlyOwner {
        require(
            amount > 0,
            "Preventa: el monto del token debe ser mayor que cero"
        );
        IERC20 token = IERC20(0xf56440Ea891495cb319d9271B65a5347ed4c3F82);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(
            allowance >= amount,
            "Preventa: el monto permitido debe ser mayor o igual al monto solicitado"
        );
        token.safeTransferFrom(msg.sender, address(this), amount);
        tokenBalance[presaleWallet] = tokenBalance[presaleWallet].add(amount);
        emit TokensAdded(amount);
    }
}
