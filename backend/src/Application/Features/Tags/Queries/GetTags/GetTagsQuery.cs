using MediatR;
using AutoMapper;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Tags.DTOs;

namespace AI.ScreenshotOrganizer.Application.Features.Tags.Queries.GetTags;

public record GetTagsQuery : IRequest<IReadOnlyList<TagDto>>;

public class GetTagsQueryHandler : IRequestHandler<GetTagsQuery, IReadOnlyList<TagDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IMapper _mapper;

    public GetTagsQueryHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _mapper = mapper;
    }

    public async Task<IReadOnlyList<TagDto>> Handle(GetTagsQuery request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var tags = await _unitOfWork.Tags.GetUserTagsAsync(userId, cancellationToken);
        return _mapper.Map<IReadOnlyList<TagDto>>(tags);
    }
}
