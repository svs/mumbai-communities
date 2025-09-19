# Authentication Setup & Testing

This document outlines the comprehensive authentication testing and email configuration implemented for the MCGM Ward Boundary Rails application.

## Controller Tests Implemented

### 1. Registrations Controller (`test/controllers/users/registrations_controller_test.rb`)
- **User Registration**: Tests valid and invalid registration scenarios
- **Email Validation**: Ensures proper email format validation
- **Password Security**: Tests password length, confirmation matching
- **Duplicate Email Prevention**: Prevents users from registering with existing emails
- **Account Management**: Tests for editing registration and account deletion
- **Authentication Integration**: Ensures users are automatically signed in after registration

### 2. Sessions Controller (`test/controllers/users/sessions_controller_test.rb`)
- **Sign In Flow**: Tests valid/invalid email and password combinations
- **Security Features**: CSRF protection, remember me functionality
- **Session Management**: Sign in/sign out workflow testing
- **API Support**: JSON format responses for API usage
- **Tracking**: Sign-in count and timestamp tracking
- **Redirects**: Proper handling of intended page redirects

### 3. Passwords Controller (`test/controllers/users/passwords_controller_test.rb`)
- **Password Reset Request**: Email sending for valid/invalid addresses
- **Security**: No information disclosure for non-existent accounts
- **Token Validation**: Valid, invalid, and expired token handling
- **Password Update**: New password setting with proper validation
- **Email Integration**: Comprehensive email delivery testing
- **API Support**: JSON responses for password reset operations

## Email Configuration

### Development Environment
- **Letter Opener Web**: Configured for email preview at `/letter_opener`
- **Gem Addition**: Added `letter_opener_web` to development group
- **Route Setup**: Development-only mounting of Letter Opener interface
- **Delivery Method**: Set to `:letter_opener_web` for email testing

### Production Environment
- **SMTP Configuration**: Environment variable-based SMTP setup
- **Security**: Proper SSL/TLS configuration with STARTTLS
- **Host Settings**: Configurable application host for email links
- **Error Handling**: Email delivery errors are properly raised
- **Default Settings**: Gmail SMTP as default with override capability

### Environment Variables Required for Production
```bash
# Email Configuration
APP_HOST=your-domain.com
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=your-domain.com
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_AUTH=plain
SMTP_STARTTLS=true
DEVISE_MAILER_SENDER=noreply@your-domain.com
```

## Key Features Implemented

### User Model Enhancements
- **Dependent Nullify**: Proper handling of user deletion with related records
- **Location Integration**: Users need location setup after registration
- **OAuth Support**: Google OAuth2 integration maintained

### Application Controller Updates
- **Parameter Sanitization**: Proper strong parameters for Devise forms
- **Redirect Logic**: Smart redirects based on user location setup status
- **Authentication Requirements**: Global authentication with appropriate exceptions

### Devise Configuration
- **Mailer Sender**: Environment-configurable sender address
- **Token Expiration**: 6-hour password reset token validity
- **Security Settings**: Proper CSRF protection and session management
- **Hotwire Integration**: Compatible with Turbo/Stimulus framework

## Testing Coverage

The test suite covers:
- ✅ **42 test cases** across all authentication controllers
- ✅ **Email delivery verification** with proper assertions
- ✅ **Security scenarios** including CSRF and token validation
- ✅ **API compatibility** with JSON format responses
- ✅ **Error handling** for edge cases and invalid inputs
- ✅ **Integration testing** with proper sign in/out workflows

## Development Workflow

1. **Email Testing**: Visit `http://localhost:3000/letter_opener` to view sent emails
2. **Running Tests**: Use `bundle exec rails test test/controllers/users/`
3. **Environment Setup**: Configure `.env` file with development SMTP settings
4. **Production Deploy**: Set environment variables on production server

## Security Considerations

- **Password Requirements**: Minimum 6 characters with confirmation
- **Token Security**: Reset tokens expire after 6 hours
- **CSRF Protection**: Enabled for all authentication forms
- **Rate Limiting**: Consider implementing for password reset requests
- **Email Security**: No information disclosure about account existence

This authentication system provides a robust foundation for user management with comprehensive testing coverage and production-ready email configuration.