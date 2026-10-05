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
    private readonly ISplitPaymentPlanRepository _splitPlanRepository;
    private readonly IConfiguration _configuration;
    private readonly ILogger<PaymentService> _logger;

    public PaymentService(
        IPaymentRepository paymentRepository,
        IOrderRepository orderRepository,
        ITableRepository tableRepository,
        IQrSessionRepository qrSessionRepository,
        IRestaurantRepository restaurantRepository,
        ISplitPaymentPlanRepository splitPlanRepository,
        IConfiguration configuration,
        ILogger<PaymentService> logger)
    {
        _paymentRepository = paymentRepository;
        _orderRepository = orderRepository;
        _tableRepository = tableRepository;
        _qrSessionRepository = qrSessionRepository;
        _restaurantRepository = restaurantRepository;
        _splitPlanRepository = splitPlanRepository;
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

    // ── Müşteri — Ödeme durumu (Seçerek/Bölerek/Hepsini Öde ekranı) ──────

    public async Task<OrderPaymentStateResponseDto> GetOrderPaymentStateAsync(int tableId, string sessionKey)
    {
        var table = await ValidateSessionForReadAsync(tableId, sessionKey);

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id);

        // Aktif sipariş yoksa, YALNIZCA çok yakın zamanda (son 5 dk içinde)
        // tamamen ödenmiş bir sipariş varsa onu göster — bu, tam ödeme sonrası
        // session rotate edildiği anki kısa geçiş penceresi için gerekli.
        // Masanın günler/saatler önceki eski geçmiş siparişlerini asla döndürmez,
        // yoksa yeni bir müşteri QR okutur okutmaz "ödeme tamamlandı" görür.
        if (order is null)
        {
            var latest = await _orderRepository.GetLatestByTableAsync(table.Id);
            if (latest is not null
                && latest.PaymentStatus == OrderPaymentStatus.Paid
                && latest.UpdatedAt >= DateTime.UtcNow.AddMinutes(-5))
            {
                order = latest;
            }
        }

        if (order is null)
            throw new InvalidOperationException("Bu masada aktif sipariş bulunamadı.");

        var paidSoFar = await _paymentRepository.GetSucceededTotalAsync(order.Id);
        var activePlan = await _splitPlanRepository.GetActiveByOrderIdAsync(order.Id);

        return new OrderPaymentStateResponseDto
        {
            OrderId = order.Id,
            TotalPrice = order.TotalPrice,
            PaidAmount = paidSoFar,
            RemainingAmount = order.TotalPrice - paidSoFar,
            PaymentStatus = order.PaymentStatus.ToString(),
            Items = order.Items.Select(i => new PaymentStateItemDto
            {
                OrderItemId = i.Id,
                MenuItemName = i.MenuItem?.Name ?? string.Empty,
                MenuItemImageUrl = i.MenuItem?.ImageUrl,
                UnitPrice = i.UnitPrice,
                Quantity = i.Quantity,
                PaidQuantity = i.PaidQuantity
            }).ToList(),
            ActiveSplitPlan = activePlan is null ? null : MapPlanToDto(activePlan)
        };
    }

    // ── Müşteri — "Bölerek Öde" plan oluşturma / iptal ───────────────────

    public async Task<SplitPaymentPlanResponseDto> CreateSplitPlanAsync(int tableId, CreateSplitPlanRequestDto request)
    {
        if (request.TotalPeople < 2)
            throw new ArgumentException("Bölüşüm en az 2 kişi ile yapılabilir.");

        var table = await ValidateSessionAsync(tableId, request.SessionKey);

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id)
            ?? throw new InvalidOperationException("Bu masada aktif sipariş bulunamadı.");

        if (order.PaymentStatus == OrderPaymentStatus.Paid)
            throw new InvalidOperationException("Bu sipariş zaten ödenmiş.");

        var existingPlan = await _splitPlanRepository.GetActiveByOrderIdAsync(order.Id);
        if (existingPlan is not null)
            throw new InvalidOperationException("Bu sipariş için zaten aktif bir bölüşüm planı var.");

        var paidSoFar = await _paymentRepository.GetSucceededTotalAsync(order.Id);
        var remaining = order.TotalPrice - paidSoFar;

        if (remaining <= 0)
            throw new InvalidOperationException("Ödenecek tutar kalmadı.");

        var plan = new SplitPaymentPlan
        {
            OrderId = order.Id,
            TotalPeople = request.TotalPeople,
            TotalAmount = remaining,
            SharesPaid = 0,
            Status = SplitPlanStatus.Active,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _splitPlanRepository.CreateAsync(plan);
        return MapPlanToDto(created);
    }

    public async Task CancelSplitPlanAsync(int tableId, int planId, CancelSplitPlanRequestDto request)
    {
        await ValidateSessionAsync(tableId, request.SessionKey);

        var plan = await _splitPlanRepository.GetByIdAsync(planId)
            ?? throw new KeyNotFoundException($"Bölüşüm planı bulunamadı: {planId}");

        if (plan.Order.TableId != tableId)
            throw new UnauthorizedAccessException("Bu plana erişim yetkiniz yok.");

        if (plan.Status != SplitPlanStatus.Active)
            throw new InvalidOperationException("Bu plan zaten aktif değil.");

        if (plan.SharesPaid > 0)
            throw new InvalidOperationException("En az bir pay ödendiği için bölüşüm iptal edilemez.");

        plan.Status = SplitPlanStatus.Cancelled;
        await _splitPlanRepository.UpdateAsync(plan);
    }

    // ── Müşteri — "Bölerek Öde" pay ödemesi → doğrudan iyzico checkout ───

    public async Task<IyzicoCheckoutResponseDto> PaySplitShareAsync(
        int tableId, int planId, PaySplitShareRequestDto request, string buyerIp)
    {
        if (request.Shares < 1)
            throw new ArgumentException("Pay sayısı en az 1 olmalı.");

        var table = await ValidateSessionAsync(tableId, request.SessionKey);

        var plan = await _splitPlanRepository.GetByIdAsync(planId)
            ?? throw new KeyNotFoundException($"Bölüşüm planı bulunamadı: {planId}");

        if (plan.Order.TableId != table.Id)
            throw new UnauthorizedAccessException("Bu plana erişim yetkiniz yok.");

        if (plan.Status != SplitPlanStatus.Active)
            throw new InvalidOperationException("Bu bölüşüm planı artık aktif değil.");

        var remainingShares = plan.TotalPeople - plan.SharesPaid;
        if (request.Shares > remainingShares)
            throw new InvalidOperationException($"En fazla {remainingShares} pay ödeyebilirsiniz.");

        var amount = plan.TotalAmount / plan.TotalPeople * request.Shares;

        var payment = new PaymentEntity
        {
            OrderId = plan.OrderId,
            Amount = amount,
            Method = PaymentMethod.Iyzico,
            SplitType = SplitType.Equal,
            Status = PaymentStatus.Pending,
            SplitPaymentPlanId = plan.Id,
            SharesCovered = request.Shares,
            CreatedAt = DateTime.UtcNow
        };
        var created = await _paymentRepository.CreateAsync(payment);

        // SharesPaid artışı webhook başarılı olduğunda SettleSucceededPaymentAsync'te yapılıyor.
        return await InitiateIyzicoCheckoutForPaymentAsync(table, created, buyerIp);
    }

    // ── Müşteri — "Seçerek Öde" → doğrudan iyzico checkout ────────────────

    public async Task<IyzicoCheckoutResponseDto> PaySelectedItemsAsync(
        int tableId, PaySelectedItemsRequestDto request, string buyerIp)
    {
        if (request.Items is null || request.Items.Count == 0)
            throw new ArgumentException("En az bir ürün seçilmeli.");

        var table = await ValidateSessionAsync(tableId, request.SessionKey);

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id)
            ?? throw new InvalidOperationException("Bu masada aktif sipariş bulunamadı.");

        if (order.PaymentStatus == OrderPaymentStatus.Paid)
            throw new InvalidOperationException("Bu sipariş zaten ödenmiş.");

        var activePlan = await _splitPlanRepository.GetActiveByOrderIdAsync(order.Id);
        if (activePlan is not null)
            throw new InvalidOperationException(
                "Eşit bölüşüm başlatıldığı için ürün seçerek ödeme yapılamaz.");

        var paymentItems = new List<Data.Entities.PaymentItem>();
        decimal amount = 0;

        foreach (var line in request.Items)
        {
            if (line.Quantity <= 0)
                throw new ArgumentException("Adet sıfırdan büyük olmalı.");

            var item = order.Items.FirstOrDefault(i => i.Id == line.OrderItemId)
                ?? throw new KeyNotFoundException($"Sipariş kalemi bulunamadı: {line.OrderItemId}");

            var unpaid = item.Quantity - item.PaidQuantity;
            if (line.Quantity > unpaid)
                throw new InvalidOperationException(
                    $"'{item.MenuItem?.Name}' için en fazla {unpaid} adet ödenebilir.");

            amount += item.UnitPrice * line.Quantity;
            paymentItems.Add(new Data.Entities.PaymentItem
            {
                OrderItemId = item.Id,
                Quantity = line.Quantity
            });
        }

        var payment = new PaymentEntity
        {
            OrderId = order.Id,
            Amount = amount,
            Method = PaymentMethod.Iyzico,
            SplitType = SplitType.ByItem,
            Status = PaymentStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            PaymentItems = paymentItems
        };

        var created = await _paymentRepository.CreateAsync(payment);
        return await InitiateIyzicoCheckoutForPaymentAsync(table, created, buyerIp);
    }

    // ── Müşteri — "Hepsini Öde" → doğrudan iyzico checkout ────────────────

    public async Task<IyzicoCheckoutResponseDto> CreateIyzicoCheckoutAsync(
        int tableId, InitiateIyzicoPaymentRequestDto request, string buyerIp)
    {
        var table = await ValidateSessionAsync(tableId, request.SessionKey);

        var order = await _orderRepository.GetActiveOrderByTableAsync(table.Id)
            ?? throw new InvalidOperationException("Bu masada aktif sipariş bulunamadı.");

        if (order.PaymentStatus == OrderPaymentStatus.Paid)
            throw new InvalidOperationException("Bu sipariş zaten ödenmiş.");

        var activePlan = await _splitPlanRepository.GetActiveByOrderIdAsync(order.Id);
        if (activePlan is not null)
            throw new InvalidOperationException(
                "Eşit bölüşüm başlatıldığı için tüm tutar tek seferde ödenemez.");

        var paidSoFar = await _paymentRepository.GetSucceededTotalAsync(order.Id);
        var remaining = order.TotalPrice - paidSoFar;

        if (remaining <= 0)
            throw new InvalidOperationException("Ödenecek tutar kalmadı.");

        var payment = new PaymentEntity
        {
            OrderId = order.Id,
            Amount = remaining,
            Method = PaymentMethod.Iyzico,
            SplitType = SplitType.Full,
            Status = PaymentStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        var created = await _paymentRepository.CreateAsync(payment);

        return await InitiateIyzicoCheckoutForPaymentAsync(table, created, buyerIp);
    }

    // ── iyzico checkout başlatma — Full/ByItem/Equal ortak mantığı ────────

    /// <summary>
    /// Önceden oluşturulmuş (Pending) bir PaymentEntity için iyzico checkout
    /// başlatır. Tutar payment.Amount'tan gelir — bu sayede aynı kod hem
    /// "Hepsini Öde" (kalan tutar), hem "Seçerek Öde" (seçilen kalemler
    /// toplamı), hem de "Bölerek Öde" (pay tutarı) için çalışır.
    /// NOT: Müşteriden ayrı bir fatura/iletişim formu almıyoruz — iyzico'nun
    /// zorunlu tuttuğu buyer alanları için misafir bilgisi kullanılıyor.
    /// Gerçek fatura/KVKK ihtiyaçlarına göre prod öncesi gözden geçirilmeli.
    /// </summary>
    private async Task<IyzicoCheckoutResponseDto> InitiateIyzicoCheckoutForPaymentAsync(
        RestaurantTable table, PaymentEntity payment, string buyerIp)
    {
        var restaurant = await _restaurantRepository.GetByIdAsync(table.RestaurantId)
            ?? throw new KeyNotFoundException("Restoran bulunamadı.");

        if (string.IsNullOrEmpty(restaurant.IyzicoSubMerchantKey) || !restaurant.IsIyzicoApproved)
            throw new InvalidOperationException("Bu restoran henüz online ödeme almaya hazır değil.");

        var priceText = payment.Amount.ToString("F2", System.Globalization.CultureInfo.InvariantCulture);
        var callbackBase = _configuration["Iyzico:CallbackBaseUrl"]?.TrimEnd('/') ?? string.Empty;
        var options = IyzicoOptionsFactory.Build(_configuration);

        var initRequest = new CreateCheckoutFormInitializeRequest
        {
            Locale = Locale.TR.ToString(),
            ConversationId = Guid.NewGuid().ToString(),
            Price = priceText,
            PaidPrice = priceText,
            Currency = Currency.TRY.ToString(),
            BasketId = $"payment-{payment.Id}",
            PaymentGroup = PaymentGroup.PRODUCT.ToString(),
            CallbackUrl = $"{callbackBase}/api/public/payments/iyzico-callback",
            Buyer = new Buyer
            {
                Id = $"guest-{table.Id}-{DateTime.UtcNow.Ticks}",
                Name = "Misafir",
                Surname = $"Masa{table.TableNumber}",
                GsmNumber = "+905000000000",
                Email = "guest@taptable.com",
                IdentityNumber = "74300864791",
                RegistrationAddress = restaurant.Address ?? "Adres belirtilmedi",
                City = "Istanbul",
                Country = "Turkey",
                Ip = buyerIp
            },
            ShippingAddress = new Address
            {
                ContactName = "Misafir",
                City = "Istanbul",
                Country = "Turkey",
                Description = restaurant.Address ?? "Adres belirtilmedi",
                ZipCode = "34000"
            },
            BillingAddress = new Address
            {
                ContactName = "Misafir",
                City = "Istanbul",
                Country = "Turkey",
                Description = restaurant.Address ?? "Adres belirtilmedi",
                ZipCode = "34000"
            },
            BasketItems = new List<BasketItem>
    {
        new BasketItem
        {
            Id = $"payment-{payment.Id}-item",
            Name = $"Masa {table.TableNumber} Ödemesi",
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

        payment.IyzicoPaymentId = result.Token;
        await _paymentRepository.UpdateAsync(payment);

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
            var transactionId = result.PaymentItems?.FirstOrDefault()?.PaymentTransactionId;

            var reloaded = await _paymentRepository.GetByIdWithDetailsAsync(payment.Id) ?? payment;
            reloaded.IyzicoPaymentTransactionId = transactionId;
            reloaded.IyzicoPaymentId = result.PaymentId;

            await SettleSucceededPaymentAsync(reloaded);
            return true;
        }

        payment.Status = PaymentStatus.Failed;
        await _paymentRepository.UpdateAsync(payment);
        return false;
    }

    // ── GEÇİCİ — sandbox'ta callback tetiklenmezse elle onay için ────────
    // Artık normal akışta kullanılmıyor (checkout doğrudan iyzico'ya bağlı).
    // Sadece test/sandbox arızasında dev tool olarak kalsın diye bırakıldı.

    //public async Task<PaymentResponseDto> ConfirmTestPaymentAsync(int paymentId)
    //{
    //    var payment = await _paymentRepository.GetByIdWithDetailsAsync(paymentId)
    //        ?? throw new KeyNotFoundException($"Ödeme bulunamadı: {paymentId}");

    //    if (payment.Status == PaymentStatus.Succeeded)
    //        return MapToDto(payment);

    //    await SettleSucceededPaymentAsync(payment);
    //    return MapToDto(payment);
    //}

    // ── Helpers ──────────────────────────────────────────────────────────

    private async Task SettleSucceededPaymentAsync(PaymentEntity payment)
    {
        payment.Status = PaymentStatus.Succeeded;
        await _paymentRepository.UpdateAsync(payment);

        if (payment.SplitPaymentPlanId is int planId)
        {
            var plan = await _splitPlanRepository.GetByIdAsync(planId);
            if (plan is not null)
            {
                plan.SharesPaid += payment.SharesCovered;
                if (plan.SharesPaid >= plan.TotalPeople)
                    plan.Status = SplitPlanStatus.Completed;

                await _splitPlanRepository.UpdateAsync(plan);
            }
        }

        var order = await _orderRepository.GetByIdInternalAsync(payment.OrderId);
        if (order is null) return;

        if (payment.PaymentItems is { Count: > 0 })
        {
            foreach (var paymentItem in payment.PaymentItems)
            {
                var orderItem = order.Items.FirstOrDefault(i => i.Id == paymentItem.OrderItemId);
                if (orderItem is not null)
                    orderItem.PaidQuantity += paymentItem.Quantity;
            }
        }

        await SettleOrderIfFullyPaidAsync(order);
    }

    /// <summary>
    /// Ödeme tutarına göre PaymentStatus'u günceller (Paid/PartiallyPaid).
    /// ÖNEMLİ: Paid olması TEK BAŞINA masayı kapatmaz. Masa/sipariş ancak
    /// Paid + (iptal hariç) TÜM ürünler Served olduğunda Completed'a düşer
    /// ve boşalır — aksi halde ödeme kaydedilir (PaidQuantity işaretlenir,
    /// iyzico onayı alınır) ama masa Dolu kalmaya devam eder. Ürünler daha
    /// sonra teslim edildiğinde (garson "Teslim Edildi" der) kapanış
    /// OrderService.TryCompleteIfPaidAndServedAsync üzerinden tamamlanır.
    /// </summary>
    private async Task SettleOrderIfFullyPaidAsync(Order order)
    {
        var totalPaid = await _paymentRepository.GetSucceededTotalAsync(order.Id);

        order.PaymentStatus = totalPaid >= order.TotalPrice
            ? OrderPaymentStatus.Paid
            : OrderPaymentStatus.PartiallyPaid;

        if (order.PaymentStatus == OrderPaymentStatus.Paid)
        {
            foreach (var item in order.Items)
            {
                if (item.PaidQuantity < item.Quantity)
                    item.PaidQuantity = item.Quantity;
            }

            if (AllRelevantItemsServed(order.Items))
            {
                await CompleteOrderAndFreeTableAsync(order);
            }

            // Onay, servis durumundan bağımsız — ödeme finansal olarak
            // gerçekleşti, iyzico tarafında capture edilmeli.
            await ApproveIyzicoItemsIfNeededAsync(order);
        }

        await _orderRepository.UpdateAsync(order);
    }

    private static bool AllRelevantItemsServed(ICollection<Data.Entities.OrderItem> items)
    {
        var relevant = items.Where(i => i.Status != OrderItemStatus.Cancelled).ToList();
        return relevant.Count > 0 && relevant.All(i => i.Status == OrderItemStatus.Served);
    }

    private async Task CompleteOrderAndFreeTableAsync(Order order)
    {
        order.Status = OrderStatus.Completed;

        var table = await _tableRepository.GetByIdAsync(order.TableId, order.Table.RestaurantId);
        if (table is not null)
        {
            table.Status = TableStatus.Available;
            await _tableRepository.UpdateAsync(table);
        }

        await _qrSessionRepository.RotateSessionAsync(order.TableId, order.Table.RestaurantId);
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

    private static SplitPaymentPlanResponseDto MapPlanToDto(SplitPaymentPlan p) => new()
    {
        Id = p.Id,
        TotalPeople = p.TotalPeople,
        TotalAmount = p.TotalAmount,
        SharesPaid = p.SharesPaid,
        Status = p.Status.ToString()
    };
    private async Task<RestaurantTable> ValidateSessionForReadAsync(int tableId, string sessionKey)
    {
        if (string.IsNullOrWhiteSpace(sessionKey))
            throw new UnauthorizedAccessException("Geçersiz oturum.");

        var session = await _qrSessionRepository.GetByKeyIncludingInactiveAsync(sessionKey)
            ?? throw new UnauthorizedAccessException("Oturum geçersiz veya süresi dolmuş.");

        if (session.TableId != tableId)
            throw new UnauthorizedAccessException("Oturum bu masaya ait değil.");

        var table = await _tableRepository.GetByIdAsync(tableId)
            ?? throw new KeyNotFoundException($"Masa bulunamadı: {tableId}");

        return table;
    }
    public async Task<PaymentResponseDto> GetPaymentStatusAsync(int tableId, int paymentId, string sessionKey)
    {
        await ValidateSessionForReadAsync(tableId, sessionKey);

        var payment = await _paymentRepository.GetByIdWithDetailsAsync(paymentId)
            ?? throw new KeyNotFoundException($"Ödeme bulunamadı: {paymentId}");

        if (payment.Order.TableId != tableId)
            throw new UnauthorizedAccessException("Bu ödemeye erişim yetkiniz yok.");

        return MapToDto(payment);
    }
}