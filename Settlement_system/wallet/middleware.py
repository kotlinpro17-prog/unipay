from django.shortcuts import render, redirect
from django.contrib import messages


# URLs that count as "operations" and must be blocked for suspended banks
BLOCKED_OPERATION_URLS = [
    '/transfer/',
    '/operations/',
    '/wallets/add/',
    '/bank/university/open/',
]


class BankStatusMiddleware:
    """
    Middleware that tracks suspended bank status on every request.

    - GET requests: allowed (read-only view), but request.bank_suspended = True
      is set so templates can show a warning banner and disable buttons.
    - POST requests to operational URLs: blocked with an error page.
    - Login/logout and Central Bank pages: always allowed.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Initialize flag
        request.bank_suspended = False

        # Only apply to authenticated commercial bank users
        if (
            request.user.is_authenticated
            and getattr(request.user, 'user_type', None) == 'COMMERCIAL_BANK'
        ):
            path = request.path

            # Always allow login, logout, static, media, api, and central bank pages
            skip_paths = ['/login/', '/logout/', '/static/', '/media/', '/api/', '/central/']
            should_skip = any(path.startswith(p) for p in skip_paths)

            if not should_skip:
                try:
                    bank = request.user.managed_bank
                    if not bank.is_active:
                        request.bank_suspended = True

                        # Block POST requests to operational endpoints
                        is_operation = any(path.startswith(op) for op in BLOCKED_OPERATION_URLS)
                        if request.method == 'POST' or is_operation:
                            return render(request, 'wallet/bank_suspended.html', {
                                'bank': bank,
                                'show_back': True,
                            })
                except Exception:
                    pass

        return self.get_response(request)
