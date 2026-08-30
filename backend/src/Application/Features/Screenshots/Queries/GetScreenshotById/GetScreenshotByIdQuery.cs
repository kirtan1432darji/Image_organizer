using MediatR;
using AutoMapper;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.Queries.GetScreenshotById;

public record GetScreenshotByIdQuery(Guid Id) : IRequest<ScreenshotDto>;

public class GetScreenshotByIdQueryHandler : IRequestHandler<GetScreenshotByIdQuery, ScreenshotDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IMapper _mapper;

    public GetScreenshotByIdQueryHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _mapper = mapper;
    }

    public async Task<ScreenshotDto> Handle(GetScreenshotByIdQuery request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var screenshot = await _unitOfWork.Screenshots.GetWithDetailsByIdAsync(request.Id, userId, cancellationToken);

        if (screenshot == null)
        {
            throw new NotFoundException(nameof(Screenshot), request.Id);
        }

        return _mapper.Map<ScreenshotDto>(screenshot);
    }
}
