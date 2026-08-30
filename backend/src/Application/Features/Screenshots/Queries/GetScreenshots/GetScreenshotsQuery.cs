using MediatR;
using AutoMapper;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Common.Models;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.Queries.GetScreenshots;

public record GetScreenshotsQuery(ScreenshotFilterDto Filter) : IRequest<PagedResult<ScreenshotDto>>;

public class GetScreenshotsQueryHandler : IRequestHandler<GetScreenshotsQuery, PagedResult<ScreenshotDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IMapper _mapper;

    public GetScreenshotsQueryHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _mapper = mapper;
    }

    public async Task<PagedResult<ScreenshotDto>> Handle(GetScreenshotsQuery request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var pagedEntities = await _unitOfWork.Screenshots.GetPagedListAsync(userId, request.Filter, cancellationToken);
        var dtoList = _mapper.Map<List<ScreenshotDto>>(pagedEntities.Items);

        return new PagedResult<ScreenshotDto>(dtoList, pagedEntities.TotalCount, pagedEntities.PageNumber, pagedEntities.PageSize);
    }
}
