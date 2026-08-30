using MediatR;
using AutoMapper;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Categories.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Sync.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Tags.DTOs;

namespace AI.ScreenshotOrganizer.Application.Features.Sync.Queries.GetChangesSince;

public record GetChangesSinceQuery(DateTime Since) : IRequest<ChangesSinceResponseDto>;

public class GetChangesSinceQueryHandler : IRequestHandler<GetChangesSinceQuery, ChangesSinceResponseDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IMapper _mapper;

    public GetChangesSinceQueryHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _mapper = mapper;
    }

    public async Task<ChangesSinceResponseDto> Handle(GetChangesSinceQuery request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var screenshots = await _unitOfWork.Screenshots.GetChangesSinceAsync(userId, request.Since, cancellationToken);
        var categories = await _unitOfWork.Categories.GetChangesSinceAsync(userId, request.Since, cancellationToken);
        var tags = await _unitOfWork.Tags.GetUserTagsAsync(userId, cancellationToken);

        return new ChangesSinceResponseDto
        {
            ServerTimestamp = DateTime.UtcNow,
            Screenshots = _mapper.Map<List<ScreenshotDto>>(screenshots),
            Categories = _mapper.Map<List<CategoryDto>>(categories),
            Tags = _mapper.Map<List<TagDto>>(tags)
        };
    }
}
