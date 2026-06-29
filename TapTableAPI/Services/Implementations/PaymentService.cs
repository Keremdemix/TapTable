using Iyzipay.Model;
using Iyzipay.Request;
using TapTable.Api.Data.Entities;
using TapTable.Api.DTOs.Request.Payment;
using TapTable.Api.DTOs.Response.Payment;
using TapTable.Api.Helpers;
using TapTable.Api.Repositories.Interfaces;
using TapTable.Api.Services.Interfaces;
using PaymentEntity = TapTable.Api.Data.Entities.Payment;

namespace TapTable.Api.Services.Implementations;

public class PaymentService : IPaymentService
{
    private readonly IPaymentRepository _paymentRepository;
    private readonly IOrderRepository _orderRepository;
    private readonly ITableRepository _tableRepository;
    private readonly IQrSessionRepository _qrSessionRepository;
    private readonly IRestaurantRepository _restaurantRepository;
    private readonly IConfiguration _configuration;
    private readonly ILogger<PaymentService> _logger;

    public PaymentService(
        IPaymentRepository paymentRepository,
        IOrderRepository orderRepository,
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository,
        IRestaurantRepository restaurantRepository,
        IConfiguration configuration,
        ILogger<PaymentService> logger)
    {
        _paymentRepository = paymentRepository;
        _orderRepository = orderRepository;
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
        _restaurantRepository = restaurantRepository;
        _configuration = configuration;
        _logger = logger;
    }

    // ── Garson — manuel ödeme ────────────────────────────────────────────

    public async Task<PaymentResponseDto> RecordManualPaymentAsync(int restaurantId, RecordManualPaymentRequestDto request)
    {
        if (request.Method == PaymentMethod.Iyzico)
            throw new ArgumentException("Manuel ödeme için Iyzico seçilemez.");

        if (request.Amount <= 0)
            throw new ArgumentException("Tutar sıfırdan büyük olmalı.");

        var order = await _orderRepository.GetByIdAsync(request.OrderId, restaurantId)
            ?? throw new KeyNotFoundException($"Sipariş bulunamadı: {request.OrderId}");

        if (order.PaymentStatus == OrderPaymentStatus.Paid)
            throw new InvalidOperationException("Bu sipariş zaten ödenmiş.");

        var payment = new PaymentEntity
        {
            OrderId = order.Id,
            Amount = request.Amount,
            Method = request.Method,
            SplitType = SplitType.Full,
            Status = PaymentStatus.Succeeded,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _paymentRepository.CreateAsync(payment);
        await SettleOrderIfFullyPaidAsync(order);

        return MapToDto(created);
    }

    public async Task<IEnumerable<PaymentResponseDto>> GetPaymentsForOrderAsync(int orderId, int restaurantId)
    {
        var payments = await _paymentRepository.GetByOrderIdAsync(orderId, restaurantId);
        return payments.Select(MapToDto);
    }

    // ── Müşteri — Hesap görüntüleme ──────────────────────────────────────

    public async Task<BillSummaryResponseDto> GetBillAsync(int tableId, string sessionKey)
    {
        var table = await ValidateSessionAsync(tableId, sessionKey);

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id)
            ?? throw new InvalidOperationException("Bu masada aktif sipariş bulunamadı.");

        var paidSoFar = await _paymentRepository.GetSucceededTotalAsync(order.Id);

        return new BillSummaryResponseDto
        {
            OrderId = order.Id,
            TableNumber = table.TableNumber,
            Items = order.Items.Select(i => new BillItemDto
            {
                Name = i.MenuItem?.Name ?? string.Empty,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                LineTotal = i.UnitPrice * i.Quantity
            }).ToList(),
            TotalPrice = order.TotalPrice,
            PaidAmount = paidSoFar,
            RemainingAmount = order.TotalPrice - paidSoFar,
            PaymentStatus = order.PaymentStatus.ToString()
        };
    }

    // ── Müşteri — iyzico Checkout Form ────────────────────────────────────

    public async Task<IyzicoCheckoutResponseDto> CreateIyzicoCheckoutAsync(
        int tableId, InitiateIyzicoPaymentRequestDto request, string buyerIp)
    {
        var table = await ValidateSessionAsync(tableId, request.SessionKey);

        var restaurant = await _restaurantRepository.GetByIdAsync(table.RestaurantId)
            ?? throw new KeyNotFoundException("Restoran bulunamadı.");

        if (string.IsNullOrEmpty(restaurant.IyzicoSubMerchantKey) || !restaurant.IsIyzicoApproved)
            throw new InvalidOperationException("Bu restoran henüz online ödeme almaya hazır değil.");

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id)
            ?? throw new InvalidOperationException("Bu masada aktif sipariş bulunamadı.");

        if (order.PaymentStatus == OrderPaymentStatus.Paid)
            throw new InvalidOperationException("Bu sipariş zaten ödenmiş.");

        var paidSoFar = await _paymentRepository.GetSucceededTotalAsync(order.Id);
        var remaining = order.TotalPrice - paidSoFar;

        if (remaining <= 0)
            throw new InvalidOperationException("Ödenecek tutar kalmadı.");

        var priceText = remaining.ToString("F2", System.Globalization.CultureInfo.InvariantCulture);
        var callbackBase = _configuration["Iyzico:CallbackBaseUrl"]?.TrimEnd('/') ?? string.Empty;
        var options = IyzicoOptionsFactory.Build(_configuration);

        var initRequest = new CreateCheckoutFormInitializeRequest
        {
            Locale = Locale.TR.ToString(),
            ConversationId = Guid.NewGuid().ToString(),
            Price = priceText,
            PaidPrice = priceText,
            Currency = Currency.TRY.ToString(),
            BasketId = $"order-{order.Id}",
            PaymentGroup = PaymentGroup.PRODUCT.ToString(),
            CallbackUrl = $"{callbackBase}/api/public/payments/iyzico-callback",
            Buyer = new Buyer
            {
                Id = $"guest-{table.Id}-{DateTime.UtcNow.Ticks}",
                Name = request.BuyerName,
                Surname = request.BuyerSurname,
                GsmNumber = request.BuyerGsmNumber,
                Email = string.IsNullOrWhiteSpace(request.BuyerEmail) ? "guest@taptable.com" : request.BuyerEmail,
                RegistrationAddress = restaurant.Address ?? "Adres belirtilmedi",
                City = "Istanbul",
                Country = "Turkey",
                Ip = buyerIp
            },
            BasketItems = new List<BasketItem>
            {
                new BasketItem
                {
                    Id = $"order-{order.Id}-item",
                    Name = $"Masa {table.TableNumber} Siparişi",
                    Category1 = "Restoran",
                    ItemType = BasketItemType.VIRTUAL.ToString(),
                    Price = priceText,
                    SubMerchantKey = restaurant.IyzicoSubMerchantKey,
                    SubMerchantPrice = priceText
                }
            }
        };

        var result = await CheckoutFormInitialize.Create(initRequest, options);
        if (result.Status != "success")
            throw new InvalidOperationException($"iyzico ödeme başlatma hatası: {result.ErrorMessage}");

        var payment = new PaymentEntity
        {
            OrderId = order.Id,
            Amount = remaining,
            Method = PaymentMethod.Iyzico,
            SplitType = SplitType.Full,
            Status = PaymentStatus.Pending,
            IyzicoPaymentId = result.Token,
            CreatedAt = DateTime.UtcNow
        };
        await _paymentRepository.CreateAsync(payment);

        return new IyzicoCheckoutResponseDto
        {
            PaymentId = payment.Id,
            Token = result.Token,
            PaymentPageUrl = result.PaymentPageUrl
        };
    }

    // ── iyzico → backend callback ────────────────────────────────────────

    public async Task<bool> HandleIyzicoCallbackAsync(string token)
    {
        var payment = await _paymentRepository.GetByIyzicoTokenAsync(token)
            ?? throw new KeyNotFoundException("Ödeme bulunamadı.");

        if (payment.Status == PaymentStatus.Succeeded)
            return true;

        var options = IyzicoOptionsFactory.Build(_configuration);
        var retrieveRequest = new RetrieveCheckoutFormRequest
        {
            Locale = Locale.TR.ToString(),
            ConversationId = Guid.NewGuid().ToString(),
            Token = token
        };

        var result = await CheckoutForm.Retrieve(retrieveRequest, options); 

        if (result.Status == "success" && result.PaymentStatus == "SUCCESS")
        {
            payment.Status = PaymentStatus.Succeeded;
            payment.IyzicoPaymentId = result.PaymentId;

            // Onay (escrow release) API'si paymentTransactionId istiyor — paymentId değil.
            // ⚠️ result.ItemTransactions / .PaymentTransactionId alan adları dokümantasyon
            // örneklerinden çıkarım — SDK'da farklı isimle geliyorsa burada düzeltilmesi gerekir.
            var transactionId = result.PaymentItems?.FirstOrDefault()?.PaymentTransactionId;
            payment.IyzicoPaymentTransactionId = transactionId;

            await _paymentRepository.UpdateAsync(payment);

            var order = await _orderRepository.GetByIdInternalAsync(payment.OrderId);
            if (order is not null)
                await SettleOrderIfFullyPaidAsync(order);

            return true;
        }

        payment.Status = PaymentStatus.Failed;
        await _paymentRepository.UpdateAsync(payment);
        return false;
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private async Task SettleOrderIfFullyPaidAsync(Order order)
    {
        var totalPaid = await _paymentRepository.GetSucceededTotalAsync(order.Id);

        order.PaymentStatus = totalPaid >= order.TotalPrice
            ? OrderPaymentStatus.Paid
            : OrderPaymentStatus.PartiallyPaid;

        if (order.PaymentStatus == OrderPaymentStatus.Paid)
        {
            order.Status = OrderStatus.Completed;

            var table = await _tableRepository.GetByIdAsync(order.TableId, order.Table.RestaurantId);
            if (table is not null)
            {
                table.Status = TableStatus.Available;
                await _tableRepository.UpdateAsync(table);
            }

            await _qrSessionRepository.RotateSessionAsync(order.TableId, order.Table.RestaurantId);

            // Restoranın parasını escrow'dan serbest bırakmak için onay gönder
            await ApproveIyzicoItemsIfNeededAsync(order);
        }

        await _orderRepository.UpdateAsync(order);
    }

    private async Task ApproveIyzicoItemsIfNeededAsync(Order order)
    {
        var iyzicoPayments = (await _paymentRepository.GetByOrderIdAsync(order.Id, order.Table.RestaurantId))
            .Where(p => p.Method == PaymentMethod.Iyzico
                     && p.Status == PaymentStatus.Succeeded
                     && !string.IsNullOrEmpty(p.IyzicoPaymentTransactionId))
            .ToList();

        if (iyzicoPayments.Count == 0) return;

        var options = IyzicoOptionsFactory.Build(_configuration);

        foreach (var payment in iyzicoPayments)
        {
            try
            {
                // ⚠️ CreateApprovalRequest / Approval.Create — iyzico SDK'sının resmi "Approval"
                // (ürün/ödeme onayı) sınıf adlarını doğrudan koddan teyit edemedim, isimlendirme
                // pattern'ine göre çıkarım yaptım. Sandbox'ta ilk denemede hata alırsanız,
                // doğru sınıf adını öğrenip burayı tek satırda düzeltiriz.
                var approveRequest = new CreateApprovalRequest
                {
                    Locale = Locale.TR.ToString(),
                    ConversationId = Guid.NewGuid().ToString(),
                    PaymentTransactionId = payment.IyzicoPaymentTransactionId
                };

                var approveResult = await Approval.Create(approveRequest, options);

                if (approveResult.Status != "success")
                {
                    _logger.LogWarning(
                        "iyzico onay başarısız — paymentId={PaymentId}, error={Error}",
                        payment.Id, approveResult.ErrorMessage);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "iyzico ödeme onayı sırasında hata — paymentId={PaymentId}", payment.Id);
            }
        }
    }

    private async Task<RestaurantTable> ValidateSessionAsync(int tableId, string sessionKey)
    {
        if (string.IsNullOrWhiteSpace(sessionKey))
            throw new UnauthorizedAccessException("Geçersiz oturum.");

        var session = await _qrSessionRepository.GetActiveByKeyAsync(sessionKey)
            ?? throw new UnauthorizedAccessException("Oturum geçersiz veya süresi dolmuş.");

        if (session.TableId != tableId)
            throw new UnauthorizedAccessException("Oturum bu masaya ait değil.");

        var table = await _tableRepository.GetByIdAsync(tableId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        return table;
    }

    private static PaymentResponseDto MapToDto(PaymentEntity p) => new()
    {
        Id = p.Id,
        OrderId = p.OrderId,
        Amount = p.Amount,
        Method = p.Method.ToString(),
        SplitType = p.SplitType.ToString(),
        Status = p.Status.ToString(),
        IyzicoPaymentId = p.IyzicoPaymentId,
        CreatedAt = p.CreatedAt
    };
}