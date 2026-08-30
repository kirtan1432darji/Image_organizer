using FluentValidation;
using MediatR;
using AutoMapper;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Search.DTOs;

namespace AI.ScreenshotOrganizer.Application.Features.Search.Queries.SearchScreenshots;

public record SearchScreenshotsQuery(string Query, Guid? CategoryId = null, string? SourceApp = null, int Limit = 50) : IRequest<SearchResultDto>;

public class SearchScreenshotsQueryValidator : AbstractValidator<SearchScreenshotsQuery>
{
    public SearchScreenshotsQueryValidator()
    {
        RuleFor(v => v.Query).NotEmpty().WithMessage("Search query keyword is required.");
        RuleFor(v => v.Limit).GreaterThan(0).LessThanOrEqualTo(100).WithMessage("Limit must be between 1 and 100.");
    }
}

public class SearchScreenshotsQueryHandler : IRequestHandler<SearchScreenshotsQuery, SearchResultDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IMapper _mapper;

    public SearchScreenshotsQueryHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _mapper = mapper;
    }

    public async Task<SearchResultDto> Handle(SearchScreenshotsQuery request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var screenshots = await _unitOfWork.Screenshots.SearchAsync(
            userId,
            request.Query,
            request.CategoryId,
            request.SourceApp,
            request.Limit,
            cancellationToken);

        var dtoList = _mapper.Map<List<ScreenshotDto>>(screenshots);

        return new SearchResultDto
        {
            Query = request.Query,
            Screenshots = dtoList,
            TotalResults = dtoList.Count
        };
    }
}
